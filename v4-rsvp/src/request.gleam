import gleam/dynamic/decode
import gleam/int
import gleam/json
import lustre/effect.{type Effect}
import plinth/javascript/date
import routes.{type EndpointUrl}
import rsvp

pub type Response {
  Response(output: String, elapsed: Float, status: Int, status_text: String)
}

// Read the clock when Lustre executes the effect, not while deciding state.
pub fn record_start(recorded recorded: fn(Int) -> message) -> Effect(message) {
  use dispatch <- effect.from

  date.now()
  |> date.get_time
  |> recorded
  |> dispatch
}

pub fn get(
  url url: EndpointUrl,
  started_at started_at: Int,
  completed completed: fn(Result(Response, String)) -> message,
) -> Effect(message) {
  rsvp.get(
    url,
    rsvp.expect_ok_response(fn(result) {
      completed(case result {
        Ok(response) ->
          case json.parse(response.body, decode.dynamic) {
            Ok(_) ->
              Ok(Response(
                output: response.body,
                elapsed: int.to_float(date.get_time(date.now()) - started_at),
                status: response.status,
                status_text: "",
              ))
            Error(_) -> Error("The response was not valid JSON")
          }
        Error(error) -> Error(error_message(error))
      })
    }),
  )
}

pub fn error_message(error: rsvp.Error(String)) -> String {
  case error {
    rsvp.BadUrl(_) -> "The endpoint URL is invalid"
    rsvp.NetworkError -> "Could not connect to the server"
    rsvp.BadBody -> "Could not read the response body"
    rsvp.HttpError(response) ->
      "Request failed: " <> int.to_string(response.status)
    rsvp.JsonError(_) -> "The response was not valid JSON"
    rsvp.UnhandledResponse(response) ->
      "Unexpected response: " <> int.to_string(response.status)
  }
}
