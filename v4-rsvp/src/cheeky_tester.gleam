import lustre
import lustre/effect.{type Effect}
import model.{type Message, type Model, Idle, Model}
import routes
import view

pub fn main() -> Nil {
  let _stop = mount()
  Nil
}

// An embedding host should call the returned function before removing the app.
// RSVP does not expose a handle for aborting in-flight requests.
pub fn mount() -> fn() -> Nil {
  let app =
    lustre.application(
      init: init,
      update: fn(model, message) { model.update(model:, message:) },
      view: view.render,
    )
  let assert Ok(runtime) = lustre.start(app, onto: "#app", with: Nil)
  fn() { lustre.send(to: runtime, message: lustre.shutdown()) }
}

pub fn init(_flags: Nil) -> #(Model, Effect(Message)) {
  let url = routes.base <> "health"
  model.start_request(model: Model(url:, request: Idle, request_id: 0), url:)
}
