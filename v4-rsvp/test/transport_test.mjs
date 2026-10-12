import assert from 'node:assert/strict'
import { get } from '../build/dev/javascript/cheeky_tester/request.mjs'
import { perform } from '../build/dev/javascript/lustre/lustre/effect.mjs'
import { Result$isOk, Result$isError } from '../build/dev/javascript/prelude.mjs'
const originalFetch = globalThis.fetch
const noop = () => {}
async function run(fetch) {
  globalThis.fetch = fetch
  return new Promise(resolve => perform(get('https://example.com/health', Date.now(), value => value), resolve, noop, noop, () => null, noop, noop, noop))
}
try {
  let result = await run(async () => new Response('{"ok":true}', {status: 200}))
  assert.ok(Result$isOk(result))
  assert.equal(result[0].output, '{"ok":true}')
  assert.equal(result[0].status, 200)
  result = await run(async () => new Response('nope', {status: 200}))
  assert.ok(Result$isError(result))
  assert.equal(result[0], 'The response was not valid JSON')
  result = await run(async () => new Response('missing', {status: 404}))
  assert.equal(result[0], 'Request failed: 404')
  result = await run(async () => { throw new TypeError('offline') })
  assert.equal(result[0], 'Could not connect to the server')
  console.log('4 transport scenarios passed')
} finally {
  globalThis.fetch = originalFetch
}
