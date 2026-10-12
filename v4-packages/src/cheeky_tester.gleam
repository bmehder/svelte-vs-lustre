import gleam/option.{None}
import gossamer/abort_signal.{type AbortSignal}
import lustre
import lustre/effect.{type Effect}
import model.{type Message, type Model, Idle, Model}
import routes
import view

pub fn main() -> Nil {
  let _stop = mount()
  Nil
}

// Hosts call this cleanup before removing the app. The shared signal aborts all its requests.
pub fn mount() -> fn() -> Nil {
  let #(scope, abort) = abort_signal.new()
  let app =
    lustre.application(
      init: init(scope:, flags: _),
      update: fn(model, message) { model.update(scope:, model:, message:) },
      view: view.render,
    )
  let assert Ok(runtime) = lustre.start(app, onto: "#app", with: Nil)
  fn() {
    abort(abort_signal.Default)
    lustre.send(to: runtime, message: lustre.shutdown())
  }
}

pub fn init(
  scope scope: AbortSignal,
  flags _flags: Nil,
) -> #(Model, Effect(Message)) {
  let url = routes.base <> "health"
  model.start_request(
    scope:,
    model: Model(url:, request: Idle, request_id: 0, cancellation: None),
    url:,
  )
}
