---
title: "State and Effects, Part 3: Checking the Request Model with TypeScript"
description: "Add TypeScript to the Svelte API explorer and examine what checked state shapes contribute without changing how the application coordinates change."
published: 2026-10-10
tags: TypeScript, Svelte, State, Effects, Cheeky Tester
---

<!-- Artwork TODO: this series needs a distinct featured image for each implementation. -->

# State and Effects, Part 3: Checking the Request Model with TypeScript

Cheeky Tester is a small API explorer: select an endpoint, request JSON, and display its response. [Part 2](/notes/state-and-effects-part-2-modeling-a-request-in-svelte/) revised its Svelte implementation around one tagged request value and a named `load` operation. That made the intended states easier to read, but JavaScript did not check that each assignment followed the model.

This version adds TypeScript to the same design. Request triggers, cancellation, state assignments, and rendering remain the same. The question is what the language can check once the developer has chosen a representation.

[Explore the TypeScript implementation](https://svelte.dev/playground/31712db59f52446ca0124cf0acba53df?version=5.57.2).

## Turn the convention into a type

The component uses `<script lang="ts">` and declares its four request shapes:

```ts
type RequestState =
  | { tag: 'idle' }
  | { tag: 'loading' }
  | {
      tag: 'success'
      data: unknown
      elapsed: number
      status: number
      statusText: string
    }
  | { tag: 'failure', message: string }

let request = $state<RequestState>({ tag: 'idle' })
```

The `tag` distinguishes the alternatives. A success value must include data, timing, and HTTP status; a failure must include a message. These are the same shapes the JavaScript version intended to use. Their description now participates in checking the program.

For example, these assignments produce type errors:

```ts
request = { tag: 'success' } // Missing the success fields
request = { tag: 'failed', message: 'Unavailable' } // Unknown tag
```

The useful addition is feedback where a mistake is introduced. Someone changing the success representation gets help finding the code that constructs or consumes it.

The existing template also benefits:

```svelte
{#if request.tag === 'failure'}
  <div>{request.message}</div>
{:else if request.tag === 'success'}
  <pre>{JSON.stringify(request.data, null, 2)}</pre>
{/if}
```

Checking the tag narrows the type, making the corresponding fields available inside that branch. Accessing `request.data` in a loading branch would be an error. This is [TypeScript's discriminated-union narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#discriminated-unions) applied to the model already present in the component.

Other annotations are small: `load` takes a `string`, and the active controller is `AbortController | undefined`. Svelte supports these type annotations directly in its [TypeScript components](https://svelte.dev/docs/svelte/typescript).

## Describe what we know about the response

The explorer prints arbitrary JSON rather than depending on a particular API schema:

```ts
const data: unknown = await response.json()
```

`unknown` records that boundary. We can pass the value to `JSON.stringify`, but we cannot assume it contains a property such as `data.title` without checking or narrowing it first.

A successful JSON parse establishes that the body is valid JSON. It does not establish an application-specific shape. Writing a response type or asserting one would not validate the network payload. If the interface needed particular fields, runtime validation would be another decision and another piece of code.

For this explorer, keeping the payload unknown matches what the interface actually does.

## Valid values are not valid journeys

The union describes what a request value may contain. It does not describe which state may follow another.

An assignment of a complete success value is type-correct even if the previous value was idle. The type also cannot tell whether the data belongs to the currently selected endpoint. An obsolete request could construct a perfectly valid success object.

The existing control flow still supplies those rules:

```ts
if (controller.signal.aborted) return

request = {
  tag: 'success',
  data,
  elapsed: performance.now() - startedAt,
  status: response.status,
  statusText: response.statusText
}
```

The guard decides whether this invocation may commit a result. The union checks the shape of the result it commits. Both matter, and they answer different questions.

Nor does declaring the union require every rendering branch to handle every alternative separately. Exhaustiveness can be checked with additional structure, such as checking an unhandled remainder against `never`. This component does not introduce that structure.

## The component still organizes change

Adding types makes the request model more precise, but leaves its architecture intact. The component owns reactive values; event handlers and an async operation change them; the template declares how each current value should appear.

There is something object-like about that arrangement: state and the operations that change it live together behind a component boundary. No class is required. In this implementation, the organizing pattern is imperative state change with declarative rendering.

The important qualification is that this describes the component we built. Svelte can also use pure transition functions, immutable values, and state in modules. TypeScript does not require any of those choices, just as reactive rendering does not prevent them.

Here, `load` still executes effects and decides the next state in the same function. Its tests still need controlled asynchronous work. The union improves checking without making that function pure or moving its decisions into a separate update function.

That is a useful stopping point for this experiment. Part 2 supplied a representation and a coordination policy. TypeScript now checks parts of that representation, with little additional runtime structure. The next implementation will use Gleam and Lustre to examine what changes when messages and update functions become the main path through the application. Whether that path clarifies this small explorer enough to justify its additional structure is a question for the implementation.
