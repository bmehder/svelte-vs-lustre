import lustre/effect.{type Effect}
import routes.{type EndpointUrl}

pub type Response {
  Response(output: String, elapsed: Float, status: Int, status_text: String)
}

pub type RequestController

@external(javascript, "./request_ffi.mjs", "createRequestController")
pub fn create_controller() -> RequestController

@external(javascript, "./request_ffi.mjs", "dispose")
pub fn dispose(controller: RequestController) -> Nil

@external(javascript, "./request_ffi.mjs", "start")
fn start(
  controller controller: RequestController,
  url url: EndpointUrl,
  succeeded succeeded: fn(Response) -> Nil,
  failed failed: fn(String) -> Nil,
) -> Nil

pub fn get(
  controller controller: RequestController,
  url url: EndpointUrl,
  completed completed: fn(Result(Response, String)) -> message,
) -> Effect(message) {
  use dispatch <- effect.from

  start(
    controller:,
    url:,
    succeeded: fn(response) { dispatch(completed(Ok(response))) },
    failed: fn(message) { dispatch(completed(Error(message))) },
  )
}
