import gleeunit
import gleeunit/should
import model.{
  Failure, HttpCompletedRequest, Idle, Loading, Model, Success,
  UserSelectedEndpoint,
}
import request.{Response}

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
    )
  state_after(model: old, message: UserSelectedEndpoint(url: "B"))
  |> should.equal(Model(url: "B", request: Loading, request_id: 2))
}

pub fn current_success_test() {
  let response =
    Response(output: "{}", elapsed: 12.0, status: 201, status_text: "Created")
  state_after(
    model: Model(url: "A", request: Loading, request_id: 1),
    message: HttpCompletedRequest(request_id: 1, result: Ok(response)),
  )
  |> should.equal(Model(url: "A", request: Success(response), request_id: 1))
}

pub fn current_failure_test() {
  state_after(
    model: Model(url: "A", request: Loading, request_id: 1),
    message: HttpCompletedRequest(request_id: 1, result: Error("Unavailable")),
  )
  |> should.equal(Model(
    url: "A",
    request: Failure("Unavailable"),
    request_id: 1,
  ))
}

pub fn obsolete_results_do_not_replace_loading_test() {
  let current = Model(url: "B", request: Loading, request_id: 2)
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
      model: Model(url: "A", request: Idle, request_id: 0),
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
  let idle = Model(url: "A", request: Idle, request_id: 0)
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
  let #(next, _) =
    model.update(controller: request.create_controller(), model:, message:)
  next
}
