import lustre/effect.{type Effect}
import request.{type RequestController, type Response}
import routes.{type EndpointUrl}

pub type RequestState {
  Idle
  Loading
  Success(Response)
  Failure(String)
}

pub type RequestId =
  Int

pub type Model {
  Model(url: EndpointUrl, request: RequestState, request_id: RequestId)
}

pub type Message {
  UserSelectedEndpoint(url: EndpointUrl)
  HttpCompletedRequest(request_id: RequestId, result: Result(Response, String))
}

// Constructing an effect does not execute it. Lustre runs it after update.
pub fn update(
  controller controller: RequestController,
  model model: Model,
  message message: Message,
) -> #(Model, Effect(Message)) {
  case message {
    UserSelectedEndpoint(url) -> start_request(controller:, model:, url:)
    HttpCompletedRequest(id, result) -> {
      let next = case id == model.request_id, model.request {
        True, Loading -> {
          let request = case result {
            Ok(response) -> Success(response)
            Error(message) -> Failure(message)
          }
          Model(..model, request:)
        }
        _, _ -> model
      }
      #(next, effect.none())
    }
  }
}

pub fn start_request(
  controller controller: RequestController,
  model model: Model,
  url url: EndpointUrl,
) -> #(Model, Effect(Message)) {
  let next = Model(url:, request: Loading, request_id: model.request_id + 1)
  let effect =
    request.get(controller:, url:, completed: HttpCompletedRequest(
      request_id: next.request_id,
      result: _,
    ))
  #(next, effect)
}
