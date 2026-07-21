defmodule ObscuraExamplesWeb.Router do
  use ObscuraExamplesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ObscuraExamplesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]

    plug Obscura.Phoenix.Plug,
      fields: [:params],
      mode: :assign_redacted,
      profile: :fast,
      entities: [:email, :phone, :credit_card, :us_ssn, :iban, :ip_address, :url, :domain]
  end

  scope "/", ObscuraExamplesWeb do
    pipe_through :browser

    live "/", WorkbenchLive
  end

  scope "/api", ObscuraExamplesWeb do
    pipe_through :api

    post "/redact", RedactionController, :create
  end
end
