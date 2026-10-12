# Cheeky Tester: cancellable package transport

This experiment uses gleam_fetch 1.4.1 plus Gossamer 10.0.0 fetch options and abort signals. RSVP remains unchanged in ../v4-rsvp; the original adapter remains in ../v4. No application-owned JavaScript FFI is used here.

From the workspace root:

```sh
npm run check:v4-packages
npm run build:v4-packages
npm run serve:v4-packages
```

Preview: http://127.0.0.1:8082/. Run only one app preview on that port; Docklands remains on 8000.

Each request creates a signal and cancellation function inside a managed effect. TransportProvidedCancellation returns a named RequestCancellation handle to update, which stores it only for the current pending request. Selection returns effects that cancel the previous handle and begin new work. A late cancellation-handle message returns a cancellation effect immediately. Current completion clears its handle. Request IDs independently protect state from obsolete results.

An app-wide signal combines with each request signal. The cleanup function returned by mount aborts all requests and shuts down Lustre. Embedding hosts must invoke it before removing the app. Standalone page teardown is managed by the browser; no application-owned pagehide listener is installed.

Clock reads use Gossamer performance.now inside the effect, immediately before transport starts and after reading/validating JSON. Timing is monotonic. Output retains the original server JSON formatting; HTTP status is numeric without native reason phrase. JSON syntax is validated, not a domain schema.

Eight Gleam tests verify state behavior. Seven controlled Node transport/lifecycle scenarios exercise success, malformed JSON, HTTP/network failures, supersession, late cancellation-handle cleanup, and app-scope abort during body reading. The Node harness uses internal Lustre effect.perform solely for tests.

The model contains a RequestCancellation record with a cancel function, so it is not entirely serializable data. Pure update describes invoking it as an effect rather than invoking it during a state decision. This is explicit lifecycle wiring, not automatic policy from the package.

The preview was bundled from an exact temporary source copy to avoid Desktop file-sync build stalls. Its CSS is built by Lustre dev tools from the explicit CSS entry.

References: https://gossamer.hexdocs.pm/gossamer/fetch_extra.html and https://gossamer.hexdocs.pm/gossamer/abort_signal.html

## Build tooling

Lustre dev tools build the JavaScript bundle, run Tailwind against `src/cheeky_tester.css`, and generate `dist/index.html`. The title and existing local Tailwind executable are configured in gleam.toml. No custom build.mjs wrapper is needed. The npm build shortcut runs `gleam run -m lustre/dev build --minify` in this directory. Install root npm dependencies before building; Tailwind remains a development tool.

Request callbacks are named on_cancel_available and on_completed. The first receives a RequestCancellation record, making the available cancellation capability explicit; it does not indicate that HTTP has started or a response is ready.
