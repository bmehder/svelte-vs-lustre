import { test } from 'node:test'
import assert from 'node:assert/strict'
// Exercise the compiled boundary, including the actual Gleam record constructor.
import { createRequestController, start, dispose } from '../build/dev/javascript/cheeky_tester/request_ffi.mjs'
import { Response } from '../build/dev/javascript/cheeky_tester/request.mjs'

const flush = () => new Promise(resolve => setImmediate(resolve))
const deferred = () => {
  let resolve, reject
  const promise = new Promise((yes, no) => { resolve = yes; reject = no })
  return { promise, resolve, reject }
}

test('browser boundary preserves metadata, cancels old work, and cleans up', async () => {
  const originalFetch = globalThis.fetch
  const pending = []
  globalThis.fetch = (url, options) => {
    const result = deferred()
    pending.push({ url, signal: options.signal, ...result })
    return result.promise
  }
  try {
    const requestController = createRequestController()
    const messages = []
    const succeeded = response => messages.push(['success', response])
    const failed = message => messages.push(['failure', message])
    start(requestController, 'A', succeeded, failed)
    start(requestController, 'B', succeeded, failed)
    assert.equal(pending[0].signal.aborted, true)
    pending[0].reject(new Error('late A'))
    await flush()
    assert.deepEqual(messages, [])
    assert.equal(requestController.activeController.signal, pending[1].signal)
    pending[1].resolve({ ok: true, status: 201, statusText: 'Created', json: async () => ({ title: 'B' }) })
    await flush()
    assert.equal(messages[0][0], 'success')
    const response = messages[0][1]
    assert.ok(response instanceof Response)
    assert.equal(response.output, '{\n  "title": "B"\n}')
    assert.ok(response.elapsed >= 0)
    assert.equal(response.status, 201)
    assert.equal(response.status_text, 'Created')

    start(requestController, 'C', succeeded, failed)
    pending[2].resolve({ ok: false, status: 404 })
    await flush()
    assert.deepEqual(messages[1], ['failure', 'Request failed: 404'])

    start(requestController, 'D', succeeded, failed)
    pending[3].resolve({ ok: true, json: async () => { throw new SyntaxError('Invalid JSON') } })
    await flush()
    assert.deepEqual(messages[2], ['failure', 'Invalid JSON'])

    const body = deferred()
    start(requestController, 'E', succeeded, failed)
    pending[4].resolve({ ok: true, status: 200, statusText: '', json: () => body.promise })
    await flush()
    dispose(requestController)
    assert.equal(pending[4].signal.aborted, true)
    body.resolve({ obsolete: true })
    await flush()
    assert.equal(messages.length, 3)
  } finally {
    globalThis.fetch = originalFetch
  }
})
