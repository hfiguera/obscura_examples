defmodule ObscuraExamplesWeb.RedactionControllerTest do
  use ObscuraExamplesWeb.ConnCase, async: true

  test "POST /api/redact returns Plug-assigned redacted parameters", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> post(~p"/api/redact", %{
        "email" => "rachel.green@example.com",
        "phone" => "+1 202-555-0188"
      })

    assert %{
             "data" => %{"email" => "[EMAIL]", "phone" => "[PHONE]"},
             "persisted" => false,
             "profile" => "fast"
           } = json_response(conn, 200)
  end
end
