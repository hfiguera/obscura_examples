defmodule ObscuraExamplesWeb.EfficientUnavailableTest do
  use ObscuraExamplesWeb.ConnCase, async: false

  test "missing native assets show a diagnostic and keep inference unavailable", %{conn: conn} do
    keys = ~w(OBSCURA_EFFICIENT_ASSET_DIR OBSCURA_SPACY_MODEL_DIR OBSCURA_SPACY_BINARY)
    previous = Map.new(keys, &{&1, System.get_env(&1)})
    Enum.each(keys, &System.delete_env/1)

    System.put_env(
      "OBSCURA_EFFICIENT_ASSET_DIR",
      Path.join(System.tmp_dir!(), "missing-efficient-#{System.unique_integer([:positive])}")
    )

    on_exit(fn ->
      Enum.each(previous, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end)

    {:ok, view, _html} = live(conn, ~p"/")
    view |> element(~s(button[phx-value-tool="profiles"])) |> render_click()
    view |> form("#prepare-desktop-efficient") |> render_submit()
    render_async(view, 15_000)

    assert has_element?(view, ~s([data-profile=efficient] .runtime-state.is-error))
    refute has_element?(view, ~s([data-profile=efficient] .runtime-state.is-ready))
    assert has_element?(view, "#prepare-desktop-efficient code", "mix obscura.efficient.install")
  end
end
