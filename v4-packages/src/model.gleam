import gleam/option.{type Option, None, Some}
import gossamer/abort_signal.{type AbortSignal}
import lustre/effect.{type Effect}
import request.{type RequestCancellation, type Response}
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
  Model(
    url: EndpointUrl,
    request: RequestState,
    request_id: RequestId,
    cancellation: Option(RequestCancellation),
  )
}

pub type Message {
  UserSelectedEndpoint(url: EndpointUrl)
  TransportProvidedCancellation(
    request_id: RequestId,
    cancellation: RequestCancellation,
  )
  HttpCompletedRequest(request_id: RequestId, result: Result(Response, String))
}

pub fn update(
  scope scope: AbortSignal,
  model model: Model,
  message message: Message,
) -> #(Model, Effect(Message)) {
  case message {
    UserSelectedEndpoint(url) -> start_request(scope:, model:, url:)
    TransportProvidedCancellation(id, cancellation) -> {
      case id == model.request_id, model.request {
        True, Loading -> #(
          Model(..model, cancellation: Some(cancellation)),
          effect.none(),
        )
        _, _ -> #(model, request.cancel(cancellation: Some(cancellation)))
      }
    }
    HttpCompletedRequest(id, result) -> {
      let next = case id == model.request_id, model.request {
        True, Loading -> {
          let request = case result {
            Ok(response) -> Success(response)
            Error(message) -> Failure(message)
          }
          Model(..model, request:, cancellation: None)
        }
        _, _ -> model
      }
      #(next, effect.none())
    }
  }
}

pub fn start_request(
  scope scope: AbortSignal,
  model model: Model,
  url url: EndpointUrl,
) -> #(Model, Effect(Message)) {
  let next =
    Model(
      url:,
      request: Loading,
      request_id: model.request_id + 1,
      cancellation: None,
    )
  let effect =
    effect.batch([
      request.cancel(cancellation: model.cancellation),
      request.get(
        scope:,
        url:,
        on_cancel_available: TransportProvidedCancellation(
          request_id: next.request_id,
          cancellation: _,
        ),
        on_completed: HttpCompletedRequest(
          request_id: next.request_id,
          result: _,
        ),
      ),
    ])
  #(next, effect)
}
