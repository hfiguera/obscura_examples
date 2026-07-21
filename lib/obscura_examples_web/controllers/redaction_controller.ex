defmodule ObscuraExamplesWeb.RedactionController do
  use ObscuraExamplesWeb, :controller

  def create(conn, _params) do
    redacted_params = Map.fetch!(conn.assigns.obscura_redacted, :params)

    json(conn, %{
      data: redacted_params,
      profile: "fast",
      persisted: false
    })
  end
end
