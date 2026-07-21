defmodule ObscuraExamplesWeb.WorkbenchLiveTest do
  use ObscuraExamplesWeb.ConnCase, async: true

  test "renders the stable capability workbench", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Obscura"
    assert html =~ "Text processing"
    assert has_element?(view, "#text-workbench")
    assert has_element?(view, ~s(button[phx-value-tool="profiles"]))
  end

  test "runs detection through the LiveView form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#text-workbench form", %{
      "input" => "Email rachel.green@example.com or +1 202-555-0188",
      "profile" => "fast",
      "entities" => ["email", "phone"],
      "action" => "detect"
    })
    |> render_submit()

    assert has_element?(view, ".entity-badge", "EMAIL")
    assert has_element?(view, "td", "rachel.green@example.com")
    assert has_element?(view, ".pane-heading span", "2 matches")
  end

  test "enables operators only for anonymization", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#text-operator[disabled]")

    view
    |> form("#text-workbench form", %{
      "input" => "Email rachel.green@example.com",
      "profile" => "fast",
      "entities" => ["email"],
      "action" => "anonymize"
    })
    |> render_change()

    refute has_element?(view, "#text-operator[disabled]")
    assert has_element?(view, ~s(#text-operator option[value="replace"][selected]))
  end

  test "pseudonymizes and rehydrates an LLM message through a session vault", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element(~s(button[phx-value-tool="vault"]))
    |> render_click()

    view
    |> form("#vault-workbench form", %{
      "input" => "Contact rachel.green@example.com"
    })
    |> render_submit()

    assert has_element?(view, ".flow-stage pre", "Contact <<EMAIL_001>>")

    view |> element(~s(button[phx-click="rehydrate_llm"])) |> render_click()
    assert has_element?(view, ".success-stage", "rachel.green@example.com")

    view |> element(~s(button[phx-click="stream_llm"])) |> render_click()
    assert has_element?(view, ".chunk-row code")
    assert has_element?(view, ".success-stage", "rachel.green@example.com")
  end

  test "shows stable profile readiness without downloading assets", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element(~s(button[phx-value-tool="profiles"]))
    |> render_click()

    assert has_element?(view, "#profiles-workbench")
    assert has_element?(view, "td", ":fast")
    assert has_element?(view, "td", ":balanced")
    assert has_element?(view, "td", ":accurate")
    assert has_element?(view, ".runtime-state.is-ready", "Ready")
  end

  test "gates model profiles until a reusable runtime is prepared", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, ~s(option[value="balanced"][disabled]))
    assert has_element?(view, ~s(option[value="accurate"][disabled]))

    render_submit(view, "run_text", %{
      "input" => "Rachel works in Paris.",
      "profile" => "balanced",
      "entities" => ["person", "location"],
      "action" => "detect",
      "operator" => "replace"
    })

    assert has_element?(view, "#profiles-workbench")
    assert render(view) =~ "Prepare :balanced before running inference."
  end
end
