import lustre
import lustre/effect.{type Effect}
import model.{type Message, type Model, Idle, Model}
import request.{type RequestController}
import routes
import view

pub fn main() -> Nil {
  let stop = mount()
  on_page_exit(stop)
}

// Hosts that remove this app must call the returned cleanup function first.
pub fn mount() -> fn() -> Nil {
  let controller = request.create_controller()
  let app =
    lustre.application(
      init: init(controller:, flags: _),
      update: fn(model, message) { model.update(controller:, model:, message:) },
      view: view.render,
    )
  let assert Ok(runtime) = lustre.start(app, onto: "#app", with: Nil)
  fn() {
    request.dispose(controller)
    lustre.send(to: runtime, message: lustre.shutdown())
  }
}

@external(javascript, "./request_ffi.mjs", "onPageExit")
fn on_page_exit(stop: fn() -> Nil) -> Nil

pub fn init(
  controller controller: RequestController,
  flags _flags: Nil,
) -> #(Model, Effect(Message)) {
  let url = routes.base <> "health"
  model.start_request(
    controller:,
    model: Model(url:, request: Idle, request_id: 0),
    url:,
  )
}
