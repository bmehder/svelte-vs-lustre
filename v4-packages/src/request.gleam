import gleam/dynamic/decode
import gleam/fetch
import gleam/http/request as http_request
import gleam/http/response as http_response
import gleam/int
import gleam/javascript/promise
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/time/duration
import gossamer/abort_signal.{type AbortSignal}
import gossamer/fetch_extra
import gossamer/performance
import lustre/effect.{type Effect}
import routes.{type EndpointUrl}

pub type Response {
  Response(output: String, elapsed: Float, status: Int, status_text: String)
}

pub type RequestCancellation {
  RequestCancellation(cancel: fn() -> Nil)
}

pub fn cancel(
  cancellation cancellation: Option(RequestCancellation),
) -> Effect(message) {
  use _dispatch <- effect.from

  case cancellation {
    Some(handle) -> handle.cancel()
    None -> Nil
  }
}

pub fn get(
  scope scope: AbortSignal,
  url url: EndpointUrl,
  on_cancel_available on_cancel_available: fn(RequestCancellation) -> message,
  on_completed on_completed: fn(Result(Response, String)) -> message,
) -> Effect(message) {
  use dispatch <- effect.from

  let #(signal, abort) = abort_signal.new()
  let signal = abort_signal.any([scope, signal])
  let cancellation =
    RequestCancellation(cancel: fn() { abort(abort_signal.Default) })
  cancellation |> on_cancel_available |> dispatch
  let started_at = performance.now()
  case http_request.to(url) {
    Error(_) -> dispatch(on_completed(Error("The endpoint URL is invalid")))
    Ok(request) -> {
      let options = fetch_extra.options() |> fetch_extra.set_signal(signal)
      let _pending =
        request
        |> fetch_extra.send(with: options)
        |> promise.map(result.map_error(_, TransportError))
        |> promise.try_await(read_ok_body)
        |> promise.map(result.map_error(_, error_message))
        |> promise.rescue(fn(_) { Error("Could not connect to the server") })
        |> promise.map(fn(result) {
          case result {
            Ok(response) ->
              case json.parse(response.body, decode.dynamic) {
                Ok(_) ->
                  Ok(Response(
                    output: response.body,
                    elapsed: duration.to_seconds(duration.subtract(
                      performance.now(),
                      started_at,
                    ))
                      *. 1000.0,
                    status: response.status,
                    status_text: "",
                  ))
                Error(_) -> Error("The response was not valid JSON")
              }
            Error(message) -> Error(message)
          }
        })
        |> promise.tap(fn(result) {
          case abort_signal.is_aborted(signal) {
            True -> Nil
            False -> dispatch(on_completed(result))
          }
        })
      Nil
    }
  }
}

fn read_ok_body(
  response: http_response.Response(fetch.FetchBody),
) -> promise.Promise(Result(http_response.Response(String), RequestError)) {
  case fetch_extra.is_response_ok(response) {
    False -> promise.resolve(Error(HttpError(response.status)))
    True ->
      response
      |> fetch.read_text_body
      |> promise.map(result.map_error(_, TransportError))
  }
}

type RequestError {
  HttpError(Int)
  TransportError(fetch.FetchError)
}

fn error_message(error: RequestError) -> String {
  case error {
    HttpError(status) -> "Request failed: " <> int.to_string(status)
    TransportError(fetch.NetworkError(_)) -> "Could not connect to the server"
    TransportError(fetch.UnableToReadBody) -> "Could not read the response body"
    TransportError(fetch.InvalidJsonBody) -> "The response was not valid JSON"
  }
}
