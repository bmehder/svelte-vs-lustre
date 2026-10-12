# Gleam and Lustre conventions

These are ongoing user preferences for Lustre applications in this workspace, including future implementations and article code examples.

- Name messages for the event that occurred, using Subject–Verb–Object names that identify the source and intent: `UserClickedButton`, `UserSelectedEndpoint`, `HttpCompletedRequest`. Avoid vague action names such as `Load`, `Set`, or `Update`.
- Messages describe events from outside the application. Share internal behavior through ordinary functions; do not invent user events during initialization or recursively call `update` to compose behavior.
- Prefer labeled arguments in function calls and record constructors unless their meaning is immediately obvious. When uncertain, use labels. Add labels to project-owned function parameters where needed; use the labels third-party APIs actually expose.
- When a label matches the local variable, use Gleam's shorthand: `thing:` instead of `thing: thing`. Apply it to calls and record construction/update wherever supported.
- Single obvious arguments such as `html.text("Loading…")`, `Success(response)`, and small conversions may remain positional. Do not wrap third-party functions just to add labels they do not support.
- Keep these conventions consistent in source, tests, documentation, and article examples. Check formatting and run the existing meaningful tests after edits.
- Use focused domain aliases when they improve reading a signature, such as `EndpointUrl` instead of an undifferentiated `String`. Name the role specifically. Aliases document meaning but do not validate values or create distinct types; use custom or opaque types when those guarantees are needed. Avoid aliases for every primitive by default.
- For callbacks carrying several related values, prefer a named payload type with labeled fields, such as `fn(Response) -> Nil`, over a positional list of primitive types such as `fn(String, Float, Int, String) -> Nil`. Keep the foreign-function implementation consistent with the Gleam payload type.
- Name opaque handles for their actual role. Use `RequestController` for the per-app cancellation holder rather than the broad name `Client`; reserve client terminology for an actual client abstraction.

References: [Lustre message naming](https://lustre.hexdocs.pm/guide/02-state-management.html#messages-not-actions), [Gleam label shorthand](https://tour.gleam.run/functions/label-shorthand-syntax/).
