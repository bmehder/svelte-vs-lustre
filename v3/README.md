# V3: Svelte with TypeScript

Playground: https://svelte.dev/playground/31712db59f52446ca0124cf0acba53df?version=5.57.2

Use App.svelte and the unchanged routes.js in the playground. Tailwind remains enabled. Browser-session edits must be saved in the user's signed-in playground before the shared link includes them.

## Changes from V2

- The script uses lang="ts".
- RequestState is a discriminated union specifying the intended fields for idle, loading, success, and failure.
- Reactive request state explicitly uses that union.
- The request URL parameter is a string.
- The controller is AbortController | undefined.
- Parsed response data is unknown. The explorer prints arbitrary JSON; it does not validate a particular response schema.

No runtime redesign: request triggers, abort guards, rendering and routes remain equivalent to V2. The transpiled script matches V2's transpiled script exactly, and the component markup matches exactly.

## Verification

From the project root, run npm run check. Strict svelte-check reported zero errors and zero warnings. Svelte 5.57.2 compiled the component, and live health and studioHomepage selections succeeded in the playground.

Controlled TypeScript probes derived from the actual RequestState declaration rejected:

- Success without its required fields
- An unknown tag
- Access to data in the loading case
- Access to a property of unknown response data

They accepted:

- Access to status after narrowing to success
- Direct assignment from idle to a complete success value
- A branch that handles success and treats every other state together

This implementation does not explicitly enforce exhaustiveness. TypeScript can check it through additional techniques, such as assigning an unhandled remainder to never; a union alone does not require every case to have a distinct branch.

These checks concern statically checked code. Types do not validate network payloads at runtime, enforce allowed transition sequences, or replace the existing stale-result guards. This version still has no pure transition core.
