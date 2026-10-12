import gleam/option.{None}
import gleeunit
import gleeunit/should
import gossamer/abort_signal
import model.{
  Failure, HttpCompletedRequest, Idle, Loading, Model, Success,
  UserSelectedEndpoint,
}
import request.{RequestCancellation, Response}

pub fn main() {
  gleeunit.main()
}

pub fn selection_clears_old_success_test() {
  let old =
    Model(
      url: "A",
      request: Success(Response(
        output: "{}",
        elapsed: 12.0,
        status: 200,
        status_text: "OK",
      )),
      request_id: 1,
      cancellation: None,
    )
  state_after(model: old, message: UserSelectedEndpoint(url: "B"))
  |> should.equal(Model(
    url: "B",
    request: Loading,
    request_id: 2,
    cancellation: None,
  ))
}

pub fn current_success_test() {
  let response =
    Response(output: "{}", elapsed: 12.0, status: 201, status_text: "Created")
  state_after(
    model: Model(url: "A", request: Loading, request_id: 1, cancellation: None),
    message: HttpCompletedRequest(request_id: 1, result: Ok(response)),
  )
  |> should.equal(Model(
    url: "A",
    request: Success(response),
    request_id: 1,
    cancellation: None,
  ))
}

pub fn current_failure_test() {
  state_after(
    model: Model(url: "A", request: Loading, request_id: 1, cancellation: None),
    message: HttpCompletedRequest(request_id: 1, result: Error("Unavailable")),
  )
  |> should.equal(Model(
    url: "A",
    request: Failure("Unavailable"),
    request_id: 1,
    cancellation: None,
  ))
}

pub fn obsolete_results_do_not_replace_loading_test() {
  let current =
    Model(url: "B", request: Loading, request_id: 2, cancellation: None)
  state_after(
    model: current,
    message: HttpCompletedRequest(request_id: 1, result: Error("Old failure")),
  )
  |> should.equal(current)
  state_after(
    model: current,
    message: HttpCompletedRequest(
      request_id: 1,
      result: Ok(Response(
        output: "old",
        elapsed: 1.0,
        status: 200,
        status_text: "OK",
      )),
    ),
  )
  |> should.equal(current)
}

pub fn obsolete_results_do_not_replace_success_test() {
  let current =
    Model(
      url: "B",
      request: Success(Response(
        output: "new",
        elapsed: 2.0,
        status: 200,
        status_text: "OK",
      )),
      request_id: 2,
      cancellation: None,
    )
  state_after(
    model: current,
    message: HttpCompletedRequest(request_id: 1, result: Error("Old failure")),
  )
  |> should.equal(current)
}

pub fn returning_to_same_url_still_has_new_identity_test() {
  let first =
    state_after(
      model: Model(url: "A", request: Idle, request_id: 0, cancellation: None),
      message: UserSelectedEndpoint(url: "A"),
    )
  let second =
    state_after(model: first, message: UserSelectedEndpoint(url: "B"))
  let third =
    state_after(model: second, message: UserSelectedEndpoint(url: "A"))
  state_after(
    model: third,
    message: HttpCompletedRequest(
      request_id: 1,
      result: Ok(Response(
        output: "old",
        elapsed: 1.0,
        status: 200,
        status_text: "OK",
      )),
    ),
  )
  |> should.equal(third)
  third.request_id |> should.equal(3)
}

pub fn completion_requires_pending_request_test() {
  let idle = Model(url: "A", request: Idle, request_id: 0, cancellation: None)
  state_after(
    model: idle,
    message: HttpCompletedRequest(request_id: 0, result: Error("Unexpected")),
  )
  |> should.equal(idle)
}

fn state_after(
  model model: model.Model,
  message message: model.Message,
) -> model.Model {
  let #(next, _) = model.update(scope: abort_signal.new().0, model:, message:)
  next
}

pub fn obsolete_cancellation_handle_does_not_change_model_test() {
  let current =
    Model(url: "B", request: Loading, request_id: 2, cancellation: None)
  state_after(
    model: current,
    message: model.TransportProvidedCancellation(
      request_id: 1,
      cancellation: RequestCancellation(cancel: fn() { Nil }),
    ),
  )
  |> should.equal(current)
}
