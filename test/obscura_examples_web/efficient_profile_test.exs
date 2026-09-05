defmodule ObscuraExamplesWeb.EfficientProfileTest do
  use ObscuraExamplesWeb.ConnCase, async: false

  @moduletag efficient: true

  test "prepares a reusable session runtime and releases its native worker on disconnect", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/")
    view |> element(~s(button[phx-value-tool="profiles"])) |> render_click()

    assert has_element?(view, "#prepare-desktop-efficient")
    assert has_element?(view, "#prepare-mobile-efficient")
    refute has_element?(view, "#prepare-desktop-efficient select[name=backend]")
    refute has_element?(view, "#prepare-desktop-efficient input[name=allow_download]")

    before_ports = Port.list()
    view |> form("#prepare-desktop-efficient") |> render_submit()
    render_async(view, 15_000)

    assert has_element?(view, "#prepare-desktop-efficient button[type=submit][disabled]")
    assert has_element?(view, ~s([data-profile=efficient] .runtime-state.is-ready))

    # A repeated or forged preparation event must not allocate another worker.
    render_submit(view, "prepare_profile", %{
      "profile" => "efficient",
      "backend" => "exla",
      "allow_download" => "true"
    })

    view |> element(~s(button[phx-value-tool="text"])) |> render_click()

    for _ <- 1..2 do
      view
      |> form("#text-workbench form", %{
        "input" => "José García lives in London.",
        "profile" => "efficient",
        "entities" => ["person", "location"],
        "action" => "detect"
      })
      |> render_submit()

      assert has_element?(view, ".entity-badge", "PERSON")
      assert has_element?(view, ".entity-badge", "LOCATION")
      assert has_element?(view, "td", "José García")
    end

    [worker_port] =
      Enum.filter(Port.list() -- before_ports, fn port ->
        case Port.info(port, :name) do
          {:name, name} -> String.contains?(to_string(name), "obscura-spacy-cpu")
          _ -> false
        end
      end)

    monitor = :erlang.monitor(:port, worker_port)
    GenServer.stop(view.pid, :normal)
    assert_receive {:DOWN, ^monitor, :port, ^worker_port, _reason}, 5_000
  end
end
