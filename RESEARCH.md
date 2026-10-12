# State and Effects: Questions to Carry Through the Series

This project compares four implementations of Cheeky Tester: the original Svelte JavaScript, revised Svelte JavaScript, the same revised design in TypeScript, and Gleam/Lustre. The objective is to investigate how applications manage change, not to select a winner. Article findings must follow implementation evidence.

## Original questions

- How much architectural discipline comes from the framework, the language, or the developer's choices?
- Where are valid states described, and where are valid transitions described? A coherent tagged state value does not itself centralize or validate transitions.
- What coordinates change: reactive dependencies, direct function calls, or messages interpreted by an update function? What becomes easier to trace, and what wiring must developers maintain?
- Does mutation serve as an implementation mechanism at the boundary, or as the organizing principle for relationships among state fields?
- How do component boundaries limit access to state? How does this differ from defining permitted state transformations? These approaches can coexist. Svelte runes can also live outside components; component ownership is not its only organizational option.
- Where are side effects initiated, executed, cancelled, and allowed to commit results? No architecture automatically resolves stale asynchronous responses.
- Can transition logic be tested as a pure function without mounting a component or mocking a network? What scaffolding does testing each design require?
- Does greater explicitness make the implementation simpler, or merely more explicit? Assess readability, conceptual load, extension costs, and boilerplate separately.

## What V2 actually establishes

V2 replaces four related view-state variables with one tagged request object. JavaScript follows intended shapes by convention, without static enforcement. Whole-object replacement records the chosen policy of clearing old output while loading.

Request triggers are direct calls on mount and selection changes. Cancellation and commit guards use per-invocation AbortControllers. Assignments still occur, including to a plain mutable activeController.

V2 does not introduce a pure transition function, message algebra, transition table, or runtime JSON schema. Its async load function still combines request execution and state assignments. Tests of that function use mocked effects and controlled promises. This is deliberate restraint for a small application, not evidence that a functional core could not be useful in a larger one.

## Questions for the remaining experiments

For V3, preserve V2's runtime architecture while examining union construction, narrowing, exhaustiveness where explicitly implemented, external JSON boundaries, and compile-time limits. Types describing valid states do not automatically enforce valid transition sequences or request ownership.

For V4, use idiomatic Gleam/Lustre. Examine custom types, messages, pure updates, runtime-managed effects, cancellation capabilities, stale-result handling, and pure transition testing. Do not add abstractions merely to demonstrate functional programming. Do not equate Lustre effects with general algebraic effect handlers.

Compare typed Svelte with Gleam/Lustre for language guarantees, and compare original/revised Svelte for architectural choices. Do not attribute improvements from refactoring solely to a framework.

## What V3 establishes

V3 adds RequestState as a discriminated union to V2's existing model. TypeScript checks construction and narrows fields after tag checks. The transpiled scripts and the component markup match V2, preserving its runtime architecture. Strict svelte-check passes. Controlled type probes reject incomplete success, unknown tags, data access from loading, and property access on unknown JSON; complete idle-to-success assignment and non-exhaustive branching with a fallback remain accepted.

This component has an object-like organization: local state and operations together behind a component boundary, with imperative changes and declarative rendering. This is an observation about the implementation, not a claim that Svelte requires classes or excludes pure updates or module-owned state. Part 3 can develop that observation without preempting the Lustre evidence. Decide whether a fifth synthesis article is useful after Part 4; do not reserve insights artificially or repeat them just to fill an epilogue.

## What the first V4 implementation establishes

Gleam/Lustre 5.7.1 uses RequestState custom variants, a Model with URL and request ID, UserSelectedEndpoint/HttpCompletedRequest messages, and a pure update returning a model and effect. Request completion is accepted only for the current ID while loading. Seven tests exercise the actual update using plain messages; constructing effects does not execute them.

A custom effect uses a per-instance JavaScript browser adapter for fetch, AbortController, performance timing, JSON parsing/pretty printing, and status text. This preserves the Svelte browser behavior rather than silently omitting cancellation or changing timing. RSVP is Lustre's recommended general HTTP package, but its documented interface does not directly expose all those browser details together. Count the adapter and its foreign-function trust boundary in the comparison. Successful data is a formatted String here, not a decoded domain record. JSON syntax is checked, but no domain schema is enforced.

The adapter still mutates its controller; the architectural difference is where application decisions live, not elimination of mutation. Its controlled test covers supersession, obsolete failure/body completion, HTTP failure, invalid JSON, metadata, and cleanup. Mount returns explicit cleanup; a host removing the app must call it. The standalone page handles page exit separately.

Live health and studioHomepage requests succeeded in the local browser. Gleam and transport checks pass. The experiment still has one app, so it cannot establish multi-component or team-scale claims.

## Editorial continuity

Domain naming also serves readability: V4 uses EndpointUrl and RequestId aliases for String and Int through its model, messages, and request boundary. The user values seeing domain roles in signatures alongside labels and parameter names. These aliases add no validation or type separation; do not describe them as new guarantees. Domain aliases, distinct wrappers, and validating opaque types offer different tradeoffs.

The browser cancellation holder is named RequestController rather than Client so its role is apparent before reading the JavaScript implementation. Request success callbacks carry one Response value with labeled fields rather than four positional primitives.

The user noticed that abort suppression and JavaScript exception handling still depend on discipline in the custom FFI. Distinguish typed application decisions from the trusted effect implementation. RSVP 2.0.0 is recommended by Lustre's effect documentation and supplies typed HTTP errors, response handlers, and JSON decoding. Its documented public API has no request cancellation handle. A package can own the browser FFI and general transport error handling; it does not decide which request ID still owns the application's state. The existing pure update independently rejects stale completion messages, including failures. Consider a package-based experiment before deciding the Part 4 narrative, while explicitly accounting for cancellation, timing, reason-phrase, and JSON-formatting differences. The original adapter remains in V4; a separate package experiment is now available in v4-rsvp.

Explain the ideas through concrete code before introducing vocabulary. Parts 1–3 teach state alternatives, required fields, and transitions with little terminology. Preserve that approach in Part 4; use names only when they help the reader.

Parts 1 and 2 describe concrete implementations and tradeoffs. The broader lens remains how programs organize change. Avoid letting cancellation repairs or type annotations become the entire subject.

The small app exposes asynchronous coordination well but provides limited evidence about component-heavy applications, team maintenance, or long-term scale. Discuss those as questions or extensions, not demonstrated results.

Initial expectations about Lustre's readability and code volume are hypotheses to revisit after implementation. Reactivity is compatible with functional techniques; explicit messages and pure updates also carry costs.

The series requires four distinct featured images eventually. Conclusions and any final comparison should emerge after all implementations exist.

## Package-based V4 experiment

`v4-rsvp` uses RSVP 2.0.0 for HTTP transport, gleam_json 3.1.0 to validate arbitrary JSON, and Plinth 0.11.0 for clock reads. Application source has no JavaScript foreign functions. These packages still use browser FFI internally; the boundary has moved to library implementations rather than disappeared. JSON is validated with decode.dynamic, not decoded into a domain schema.

The model retains request IDs and the current/pending completion guard. A ClockRecordedRequestStart message carries a clock reading produced by a managed effect; update remains free of clock reads. Obsolete clock events are rejected too. RSVP's callback validates JSON and records the ending clock time before dispatching completion.

Observable differences: no superseded-request cancellation, original response text instead of JSON.stringify pretty printing, numeric status without native statusText, and Date-based wall-clock timing rather than monotonic performance.now. Timing includes the clock-message scheduling interval, response reading, and JSON parsing; system-clock changes can affect it. Do not treat measured times as performance evidence between implementations. Mount returns Lustre shutdown for embedding hosts but cannot abort RSVP requests. The standalone page relies on browser document teardown rather than an application-owned pagehide listener.

Verification: nine Gleam state/error tests, four controlled package transport scenarios (success, invalid JSON, HTTP 404, network failure), successful bundle, and browser health/studioHomepage responses. The transport harness invokes Lustre's internal effect.perform only for tests; production code does not depend on that internal API. Browser screenshot v4-rsvp/preview.png. No Part 4 article drafted yet.

The package experiment demonstrates that the original FFI was a choice made to preserve specific browser behavior, not an inherent requirement for writing the request in Gleam. Package choice moves general transport handling, but relevance and lifecycle policies still require explicit design. Judge the tradeoffs before choosing the series' final implementation.

## Series ending: editorial recommendation

Recommend five articles total: the three approved Svelte articles, Part 4 covering Gleam/Lustre with both the custom adapter and RSVP experiment, and Part 5 synthesizing what the entire process teaches about organizing change. The user approved this five-article structure and drafting Parts 4 and 5.

Part 4's central subject is the move from component-owned operations to messages and explicit state transformations. Use short code examples for the model, update, effect boundary, and a pure transition test. Include RSVP as a substantial section about boundary ownership and package tradeoffs, not a separate implementation chapter with repeated model/view explanations. The application model stays largely the same while transport responsibilities move. Count naming, labels, callback payloads, and domain aliases as readability decisions rather than framework guarantees.

Part 5 is a substantive conclusion, not a recap or a verdict. Return to the original questions: valid values versus permitted transitions; state ownership versus transformation rules; mutation as mechanism versus organizing principle; execution of effects versus permission to commit results; explicitness versus simplicity; and guarantees supplied by types, frameworks, libraries, and application policy. Put small excerpts from multiple implementations alongside each other where they clarify these distinctions. Discuss what a reader can carry back into an existing Svelte, JavaScript, TypeScript, or Gleam application without changing frameworks. Do not end on Lustre as a destination or imply this sequence ranks implementations by superiority.

The user accepts lack of cancellation for this demo. A production cancellation requirement would warrant researching package capabilities or adapting the effect boundary, rather than declaring custom application JavaScript the only solution. Do not claim an alternative meets those requirements before verifying it. Distinguish writing application JavaScript from relying on JavaScript runtime/library internals.

Keep Research.md as the guiding source for every remaining draft. Teach concepts through concrete code before naming them. Avoid internal conversational history and arbitrary implementation chronology. Cancellation illustrates ownership of effects but must not displace the broader question of how change is organized.

A sixth article is justified only if the package investigation develops its own substantial question and evidence; current findings fit within Part 4. The accepted five-article structure implies five featured images if all items receive one, superseding the earlier four-image estimate. Artwork remains pending.

## Remaining drafts completed

Docklands now contains Part 4, "Messages, Updates, and Effects in Lustre", and Part 5, "What Organizes Change?", with series navigation from Part 3. Both were reviewed against source and this research guide. Corrections distinguish coordination from rendering, accurately count RSVP state/error tests, identify actual source variants in examples, and preserve intentional retained-data combinations in the synthesis. Full site build and five site tests pass; both local article routes return HTTP 200. Articles remain local work, with no commit, push, or publication. Featured images are still pending.

## Cancellation-capable package investigation

The user asked us to go beyond accepting RSVP's limitation and investigate package solutions. Hex identifies RSVP 2.0.0's upstream as hayleigh-dot-dev/rsvp. Examined all 16 current upstream issues/PRs via GitHub API; none mention cancel/abort/signal. That is not evidence about what most users do, and no adoption claim should be made. RSVP remains unchanged; do not imply a plugin can attach signals to its hidden request.

Gossamer 10.0.0 explicitly extends gleam_fetch with FetchOptions.signal and fetch_extra.send(request, with: options). abort_signal.new returns an AbortSignal and an abort function. It also provides any for combining app/request scopes and performance.now as a typed monotonic duration. Sources: https://gossamer.hexdocs.pm/gossamer/fetch_extra.html ; https://gossamer.hexdocs.pm/gossamer/abort_signal.html ; https://gossamer.hexdocs.pm/gossamer/performance.html ; https://github.com/han-tyumi/gossamer . Installed source confirms these APIs. This is an available documented solution, not an assertion of community consensus or production certification.

Implemented v4-packages alongside v4 and v4-rsvp with no application-owned JavaScript FFI. TransportPreparedRequest carries a cancellation function from the managed request effect. Model.cancel holds an optional function. Selection returns cancellation plus new request effects; current completion clears the handle; obsolete prepared messages return cancellation effects. Existing completion request-ID/current-loading guard remains independent. An app-wide abort signal combines with individual signals; mount cleanup aborts all requests and shuts down Lustre. Embedding hosts must call it. A standalone page still relies on browser document teardown.

Clock reads are inside the managed effect around transport/body/JSON validation, using Gossamer monotonic performance timing. The RSVP clock-message step is unnecessary in this variant. JSON retains server formatting and HTTP status remains numeric without native reason phrase. Parsing does not validate a domain schema. Cancellation is not a promise that the remote server undoes work already started.

Tradeoffs include explicit prepared-message/handle wiring, a function stored in the model (not wholly serializable), JavaScript-target browser bindings and trusted package internals. Types do not automatically choose relevance or cleanup policy. Scope cancellation and abort suppression supplement, rather than replace, request IDs.

Eight Gleam state tests and seven controlled Node transport/lifecycle scenarios pass, including actual signal propagation, selection-driven abort, late prepared-handle cleanup, and app-scope abort during body reading. Bundle succeeds. Preview uses existing port 8082, replacing the RSVP preview; Docklands stays on 8000. Keep all source variants for the article evidence, and update Parts 4–5 before publication: the initial either-custom-JS-or-uncancellable-RSVP framing was incomplete. Package composition must expose the capability at the transport boundary. Keep this finding subordinate to the broader investigation of how change is organized.

Parts 4 and 5 have now been revised to include the verified cancellation-capable composition and its lifecycle/serializability costs. Reviewed the rendered-source revisions against v4-packages. Docklands full build and five tests pass; revised article routes return HTTP 200. Browser health response and rapid endpoint changes succeed on the replacement 8082 preview. Confirmed only 8000 and 8082 are listening among project preview ports; 8081 remains stopped. No commit, push, or publication.

## Build tooling correction

The user questioned the custom build.mjs wrapper. Local Quiz and Lustre Tennis projects already use lustre/dev build directly with HTML settings in gleam.toml. Countdown similarly uses direct dev-tool commands, while Gleam Chat separately invokes Tailwind from npm scripts. Checked installed lustre_dev_tools 2.3.6 source: build bundles JavaScript, detects src/<entry>.css and invokes Tailwind, and generates HTML. The wrapper was unnecessary convenience scaffolding added here, not a Lustre requirement.

Removed build.mjs, root app.css, and hand-maintained index.html from all three local Lustre experiments. CSS now lives in src/cheeky_tester.css with explicit view.gleam source scanning. gleam.toml configures the existing npm Tailwind executable and page title. Root npm build scripts invoke gleam run -m lustre/dev build --minify directly. Package/runtime architecture is unchanged; development tooling still uses Bun and Tailwind. The standard build successfully produces the bundle, stylesheet, and HTML. Do not count the discarded custom build wrapper as required Lustre architecture in the articles.

## Readability observation to preserve

The user observes that descriptive message names, labels, domain aliases, and named callback payloads can increase file length while reducing the amount of meaning inferred from position, punctuation, or distant context. Discuss this as less inference per expression versus more text and wiring to scan overall, rather than equating line count with complexity. Contributions come from the chosen conventions, language syntax, and architecture; do not assert a measured or universal ratio of special characters to words. Pipelines can make sequences of transformations easier to follow than nested calls, as in RSVP's record_start callback. Include the observation naturally in the readability tradeoff discussion without conversational history.

## Five-article final continuity audit

Audited all five articles after the build-tooling correction. Updated early series framing and all artwork notes to five installments, Part4 description to cover both package approaches, restored RSVP wall-clock/clock-message explanation, aligned Gossamer excerpts, added direct Lustre build guidance, and incorporated the naming/readability tradeoff. Corrected Part5's overly broad cancellation statement. All five local routes return HTTP200; direct build instruction is present in rendered Part4. Docklands reports five tests and all50 highlighted code blocks passing with series navigation intact. Five featured images and eventual publication remain pending; no commit, push, or publish performed.

## Featured artwork

Generated five original 1774x887 editorial images with the built-in image generator, one for each article. Source copies and the exact prompt set are saved under artwork/state-and-effects. Shared dark graphite, glass, teal and amber materials connect the series visually without framework logos or a winner narrative. Subjects progress through relationships among local state, coherent snapshots, checked shapes, messages/effect boundaries, and equally weighted alternative organizations. These are conceptual illustrations, not technical diagrams. Docklands will own project-local source copies and use its existing build optimizer for WebP output, with descriptive alt text and featured-image markers in all five articles.

Featured artwork is now installed in all five Docklands Notes items and the Notes listing. Source PNGs are stored as assets/static/images/note-state-and-effects-part-N.png; built WebPs are 1000x500 and approximately27–42KB each. All five image URLs return HTTP200. Alt text, inline featured-image markers, and social metadata are present; artwork TODO comments removed. Full Docklands build, five tests, and all50 highlighted code blocks pass. Browser verified Notes cards and Part1 heading/image rendering; screenshots saved alongside the source artwork. No commit, push, or publication.
