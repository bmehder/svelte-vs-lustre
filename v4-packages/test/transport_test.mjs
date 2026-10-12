import assert from 'node:assert/strict'
import { get, RequestCancellation } from '../build/dev/javascript/cheeky_tester/request.mjs'
import * as model from '../build/dev/javascript/cheeky_tester/model.mjs'
import { new_ } from '../build/dev/javascript/gossamer/gossamer/abort_signal.ffi.mjs'
import { Default } from '../build/dev/javascript/gossamer/gossamer/abort_signal.mjs'
import { None } from '../build/dev/javascript/gleam_stdlib/gleam/option.mjs'
import { perform } from '../build/dev/javascript/lustre/lustre/effect.mjs'
import { Result$isOk, Result$isError } from '../build/dev/javascript/prelude.mjs'
const originalFetch = globalThis.fetch
const noop = () => {}
const flush = async () => { for (let i = 0; i < 20; i++) await Promise.resolve() }
const runEffect = (effect, dispatch) => perform(effect, dispatch, noop, noop, () => null, noop, noop, noop)
async function run(fetch) {
  globalThis.fetch = fetch
  const [scope] = new_()
  return new Promise(resolve => runEffect(get(scope, 'https://example.com/health', () => ({cancellationAvailable:true}), value => value), value => { if (!value.cancellationAvailable) resolve(value) }))
}
try {
  let result = await run(async () => new Response('{"ok":true}', {status:200}))
  assert.ok(Result$isOk(result))
  assert.equal(result[0].output, '{"ok":true}')
  assert.ok(result[0].elapsed >= 0)
  result = await run(async () => new Response('nope', {status:200}))
  assert.ok(Result$isError(result))
  assert.equal(result[0], 'The response was not valid JSON')
  result = await run(async () => new Response('missing', {status:404}))
  assert.equal(result[0], 'Request failed: 404')
  result = await run(async () => { throw new TypeError('offline') })
  assert.equal(result[0], 'Could not connect to the server')

  // Drive the actual model and effects: selection must abort the old fetch.
  const requests = []
  globalThis.fetch = (input, options) => new Promise((resolve, reject) => {
    requests.push({signal:options.signal, resolve})
    options.signal.addEventListener('abort', () => reject(options.signal.reason), {once:true})
  })
  const [scope, abortScope] = new_()
  let current = new model.Model('https://example.com/A', new model.Idle(), 0, new None())
  let completions = 0
  function dispatch(message) {
    if (message instanceof model.HttpCompletedRequest) completions++
    const [next, effect] = model.update(scope, current, message)
    current = next
    runEffect(effect, dispatch)
  }
  dispatch(new model.UserSelectedEndpoint('https://example.com/A'))
  dispatch(new model.UserSelectedEndpoint('https://example.com/B'))
  assert.equal(requests[0].signal.aborted, true)
  assert.equal(requests[1].signal.aborted, false)
  await flush()
  assert.equal(completions, 0)
  requests[1].resolve(new Response('{"current":true}', {status:200}))
  await new Promise(resolve => setImmediate(resolve))
  assert.ok(current.request instanceof model.Success)
  assert.equal(current.request[0].output, '{"current":true}')

  // A late cancellation-handle event must immediately cancel its own handle.
  let stopped = false
  dispatch(new model.TransportProvidedCancellation(1, new RequestCancellation(() => { stopped = true })))
  assert.equal(stopped, true)
  assert.ok(current.request instanceof model.Success)

  // Abort during response-body reading and ensure no completion is dispatched.
  let bodyController
  globalThis.fetch = async (_input, options) => {
    const body = new ReadableStream({start(controller) { bodyController = controller }})
    options.signal.addEventListener('abort', () => bodyController.error(options.signal.reason), {once:true})
    requests.push({signal:options.signal})
    return new Response(body, {status:200})
  }
  dispatch(new model.UserSelectedEndpoint('https://example.com/slow-body'))
  await flush()
  const before = completions
  abortScope(new Default())
  assert.equal(requests.at(-1).signal.aborted, true)
  await new Promise(resolve => setImmediate(resolve))
  assert.equal(completions, before)
  console.log('7 transport/lifecycle scenarios passed')
} finally {
  globalThis.fetch = originalFetch
}
