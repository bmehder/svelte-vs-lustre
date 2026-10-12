import lustre/effect.{type Effect}
import request.{type Response}
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
  ClockRecordedRequestStart(request_id: RequestId, started_at: Int)
  HttpCompletedRequest(request_id: RequestId, result: Result(Response, String))
}

// Constructing an effect does not execute it. Lustre runs it after update.
pub fn update(
  model model: Model,
  message message: Message,
) -> #(Model, Effect(Message)) {
  case message {
    UserSelectedEndpoint(url) -> start_request(model:, url:)
    ClockRecordedRequestStart(id, started_at) -> {
      let next_effect = case id == model.request_id, model.request {
        True, Loading ->
          request.get(
            url: model.url,
            started_at:,
            completed: HttpCompletedRequest(request_id: id, result: _),
          )
        _, _ -> effect.none()
      }
      #(model, next_effect)
    }
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
  model model: Model,
  url url: EndpointUrl,
) -> #(Model, Effect(Message)) {
  let next = Model(url:, request: Loading, request_id: model.request_id + 1)
  let effect =
    request.record_start(recorded: ClockRecordedRequestStart(
      request_id: next.request_id,
      started_at: _,
    ))
  #(next, effect)
}
