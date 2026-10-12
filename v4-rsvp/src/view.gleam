import gleam/float
import gleam/int
import gleam/list
import lustre/attribute as a
import lustre/element.{type Element}
import lustre/element/html as h
import lustre/event
import model.{
  type Message, type Model, Failure, Idle, Loading, Success,
  UserSelectedEndpoint,
}
import routes

pub fn render(model: Model) -> Element(Message) {
  h.main(
    [a.class("min-h-screen bg-zinc-950 px-4 py-10 text-zinc-100 sm:px-6")],
    [
      h.div([a.class("mx-auto max-w-4xl")], [
        h.header([a.class("mb-8")], [
          h.p(
            [
              a.class(
                "mb-2 text-xs font-semibold uppercase tracking-[0.25em] text-fuchsia-400",
              ),
            ],
            [h.text("CheekyCMS")],
          ),
          h.h1([a.class("text-3xl font-bold tracking-tight sm:text-4xl")], [
            h.text("API Explorer"),
          ]),
          h.p([a.class("mt-3 text-zinc-400")], [
            h.text("Choose an endpoint to inspect its live response."),
          ]),
        ]),
        h.section(
          [
            a.class(
              "overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-900 shadow-2xl",
            ),
          ],
          [
            h.div([a.class("border-b border-zinc-800 p-4 sm:p-5")], [
              h.label(
                [
                  a.for("route"),
                  a.class("mb-2 block text-sm font-medium text-zinc-300"),
                ],
                [h.text("Endpoint")],
              ),
              h.div([a.class("flex items-center gap-3")], [
                h.select(
                  [
                    a.id("route"),
                    a.value(model.url),
                    event.on_change(UserSelectedEndpoint),
                    a.class(
                      "min-w-0 flex-1 rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-2.5 text-sm text-zinc-100 outline-none transition focus:border-fuchsia-500 focus:ring-2 focus:ring-fuchsia-500/20",
                    ),
                  ],
                  list.map(routes.all(), fn(route) {
                    let #(label, path) = route
                    let url = routes.base <> path
                    h.option(
                      [a.value(url), a.selected(url == model.url)],
                      label,
                    )
                  }),
                ),
                indicator(model.request),
              ]),
              h.p([a.class("mt-3 truncate font-mono text-xs text-zinc-500")], [
                h.text(model.url),
              ]),
            ]),
            h.div([a.class("min-h-80")], [
              h.div(
                [
                  a.class(
                    "flex items-center justify-between border-b border-zinc-800 px-4 py-3 sm:px-5",
                  ),
                ],
                [
                  h.span(
                    [
                      a.class(
                        "text-xs font-semibold uppercase tracking-wider text-zinc-500",
                      ),
                    ],
                    [h.text("Response")],
                  ),
                  timing(model.request),
                  status(model.request),
                ],
              ),
              output(model.request),
            ]),
          ],
        ),
      ]),
    ],
  )
}

fn indicator(request: model.RequestState) -> Element(Message) {
  let #(color, label) = case request {
    Idle -> #("bg-zinc-500", "Idle")
    Loading -> #("animate-pulse bg-amber-400", "Loading")
    Success(_) -> #("bg-emerald-400", "Ready")
    Failure(_) -> #("bg-red-400", "Error")
  }
  h.span(
    [
      a.class("h-2.5 w-2.5 shrink-0 rounded-full " <> color),
      a.aria_label(label),
    ],
    [],
  )
}

fn timing(request: model.RequestState) -> Element(Message) {
  case request {
    Success(response) ->
      h.span([a.class("font-mono text-zinc-500")], [
        h.text(int.to_string(float.round(response.elapsed)) <> " ms"),
      ])
    Idle | Loading | Failure(_) -> h.text("")
  }
}

fn status(request: model.RequestState) -> Element(Message) {
  case request {
    Idle -> h.text("")
    Loading -> h.span([a.class("text-xs text-amber-400")], [h.text("Loading…")])
    Failure(_) ->
      h.span([a.class("text-xs text-red-400")], [h.text("Request failed")])
    Success(response) ->
      h.span([a.class("text-xs text-emerald-400")], [
        h.text(int.to_string(response.status) <> " " <> response.status_text),
      ])
  }
}

fn output(request: model.RequestState) -> Element(Message) {
  case request {
    Idle | Loading -> h.text("")
    Failure(message) ->
      h.div([a.class("p-5 text-sm text-red-300")], [h.text(message)])
    Success(response) ->
      h.pre(
        [
          a.class(
            "whitespace-pre-wrap break-words p-4 font-mono text-sm leading-6 text-zinc-300 sm:p-5",
          ),
        ],
        [h.text(response.output)],
      )
  }
}
