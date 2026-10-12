# Cheeky Tester with RSVP

A separate package-based experiment; `../v4` preserves the custom browser adapter.

Run from the workspace root:

```sh
npm run check:v4-rsvp
npm run build:v4-rsvp
npm run serve:v4-rsvp
```

Preview: http://127.0.0.1:8082/

HTTP transport uses [RSVP](https://hexdocs.pm/rsvp/2.0.0/rsvp.html), JSON syntax checking uses gleam_json, and clock reads use Plinth. Application source contains no hand-written JavaScript adapter. Packages still contain their own foreign functions.

The model rejects obsolete results by request ID. RSVP does not expose cancellation, so superseded requests continue running. Responses display validated original JSON text, numeric HTTP status without native reason phrases, and wall-clock elapsed milliseconds. Clock changes can affect timing; the interval also includes scheduling the clock message. These figures should not be used to compare framework performance.

`ClockRecordedRequestStart` comes from a managed clock effect. The update function decides whether to begin the HTTP effect and remains free of clock reads. Parsing arbitrary JSON validates syntax without checking an API-specific schema.

`mount` returns a shutdown function that an embedding host must call before removing the application. It cannot abort in-flight RSVP requests. The standalone page relies on browser document teardown.

Nine Gleam tests cover state decisions and error mapping. Four Node transport scenarios exercise the actual RSVP effect with mocked fetch responses. The test harness uses Lustre's internal effect.perform; production code does not. Run gleam test before the Node harness to generate its imported modules.

If local file synchronization stalls builds in the Desktop folder, build an exact source copy in a temporary directory. The verified preview bundle was generated that way. Its stylesheet is built by Lustre dev tools from the explicit CSS entry.

## Build tooling

Lustre dev tools build the JavaScript bundle, run Tailwind against `src/cheeky_tester.css`, and generate `dist/index.html`. The title and existing local Tailwind executable are configured in gleam.toml. No custom build.mjs wrapper is needed. The npm build shortcut runs `gleam run -m lustre/dev build --minify` in this directory. Install root npm dependencies before building; Tailwind remains a development tool.
