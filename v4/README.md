# V4: Gleam and Lustre

The same Cheeky Tester interface, endpoints, initial health request, loading-clears-output policy, success status and timing, and JSON/error display as the revised Svelte implementations.

From the project root:

```sh
npm install
cd v4
gleam deps download
cd ..
npm run check:v4
npm run build:v4
npm run serve:v4
```

Open http://127.0.0.1:8081. Requires Gleam, Node, Python for serving, and Bun on PATH (Lustre's build tool uses the installed Bun). The dependency manifest locks the Gleam packages. Build output goes in v4/dist.

## Read the application

- `src/model.gleam`: request shapes, model, messages, and update. It returns a new model and an effect description. It does not run the network or mutate the old model.
- `src/cheeky_tester.gleam`: connects init/update/view to the Lustre runtime; initial request and explicit mounting cleanup.
- `src/view.gleam`: declarative HTML functions with the same Tailwind classes as Svelte. Rendering decisions explicitly cover the request alternatives.
- `src/routes.gleam`: the same endpoint labels and paths, in the same order.
- `EndpointUrl` and `RequestId` are aliases for String and Int. They make signatures describe each value's domain role without adding parsing, validation, or distinct types.
- `src/request.gleam`: constructs a custom Lustre effect and turns completion into a typed message.
- `src/request_ffi.mjs`: browser boundary for fetch, AbortController, performance timing, and JSON formatting. It owns mutable cancellation machinery for one app instance, represented in Gleam as RequestController. This holds the active browser AbortController; it is not a general HTTP client.

## Choices to compare

Selection sends UserSelectedEndpoint. Update replaces the request with Loading, increments a request ID, and returns a request effect. Its completion becomes HttpCompletedRequest with that ID. Update accepts it only while the matching request is pending. The ID matters even if the user selects A, then B, then A again.

The browser boundary also aborts superseded requests and suppresses aborted callbacks. The model guard is independently tested: messages do not intrinsically establish ownership.

Lustre recommends RSVP for ordinary HTTP effects. This example uses a small custom effect to preserve browser cancellation, elapsed time including JSON parsing, native status text, and arbitrary JSON pretty-printing together. That adapter is part of the implementation and must be counted in any comparison. It is not all Gleam, and Lustre does not eliminate mutation at the browser boundary.

The successful payload is a formatted String rather than a decoded domain record. JSON is parsed and formatted at the browser boundary; this checks syntax, not an application-specific schema. The interface needs no specific JSON properties. Status and elapsed time arrive as typed fields.

`mount` returns cleanup that aborts pending work and shuts down the Lustre runtime. The standalone page calls it when leaving the page (except when the browser retains the page in its back/forward cache). A host removing the app must call this cleanup before removing its mount point; cleanup is not automatically inferred from DOM removal.

## Verification

Seven Gleam tests exercise the real update function with plain state and messages. They cover state replacement, current success/failure, stale results before and after success, A/B/A identity, and an unexpected completion while idle. Constructed effects are not executed in these tests.

A Node test controls the browser boundary's fetch promises and checks cancellation, stale suppression, status/timing/JSON formatting, HTTP failure, invalid JSON, and cleanup during body parsing.

The success callback receives one Response value with named fields. The adapter constructs it using the compiled Gleam constructor, and the Node test runs against the compiled adapter to check that boundary as well. Run `gleam test` (or `gleam build`) before running the Node test directly.

These are complementary checks: pure update tests do not prove that the browser adapter or its foreign-function declarations are correct.

The final source passed formatting, all seven Gleam tests, the Node boundary test, and the Lustre bundle build. The final repeat ran from an identical temporary copy because build-file locks in the Desktop folder stalled verification there. Health and studioHomepage also succeeded in the live local page. Build dependencies emit upstream warnings; the application source compiles without warnings.

## Build tooling

Lustre dev tools build the JavaScript bundle, run Tailwind against `src/cheeky_tester.css`, and generate `dist/index.html`. The title and existing local Tailwind executable are configured in gleam.toml. No custom build.mjs wrapper is needed. The npm build shortcut runs `gleam run -m lustre/dev build --minify` in this directory. Install root npm dependencies before building; Tailwind remains a development tool.
