defmodule ObscuraExamplesWeb.WorkbenchLiveTest do
  use ObscuraExamplesWeb.ConnCase, async: true

  test "renders the stable capability workbench", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Obscura"
    assert html =~ "Text processing"
    assert has_element?(view, "#text-workbench")
    assert has_element?(view, ~s(main[phx-hook="WorkbenchFocus"]))
    assert has_element?(view, ~s(#text-workbench h1[tabindex="-1"]))
    assert has_element?(view, ~s(button[phx-value-tool="profiles"]))
    assert has_element?(view, ~s(button[phx-value-tool="text"][aria-pressed="true"]))
    assert has_element?(view, ~s(button[phx-value-tool="profiles"][aria-pressed="false"]))

    view |> element(~s(button[phx-value-tool="structured"])) |> render_click()
    assert_push_event(view, "workbench:selected", %{id: "structured-workbench"})
    assert has_element?(view, ~s(button[phx-value-tool="structured"][aria-pressed="true"]))
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
    assert has_element?(view, ".pane-heading h2", "Detection result")
    assert has_element?(view, ".pane-heading span", "2 detections")
    assert has_element?(view, ".match-table th", "Detected text")
    assert has_element?(view, ".command-feedback", "Detection complete: 2 entities found")
    refute has_element?(view, ".result-pane[aria-live]")
  end

  test "uses anonymization-specific result language and columns", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#text-workbench form", %{
      "input" => "Email rachel.green@example.com",
      "profile" => "fast",
      "entities" => ["email"],
      "action" => "anonymize"
    })
    |> render_change()

    view
    |> form("#text-workbench form", %{
      "input" => "Email rachel.green@example.com",
      "profile" => "fast",
      "entities" => ["email"],
      "action" => "anonymize",
      "operator" => "replace"
    })
    |> render_submit()

    assert has_element?(view, ".pane-heading h2", "Anonymized text")
    assert has_element?(view, ".pane-heading span", "1 replacement")
    assert has_element?(view, ".match-table th", "Replacement")
    assert has_element?(view, ".match-table th", "Operator")
    refute has_element?(view, ".match-table th", "Score")
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

  test "limits entity choices to the selected profile capabilities", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element(~s(button[phx-click="toggle_advanced_entities"])) |> render_click()
    assert has_element?(view, ~s|input[value="street_address"]:not([disabled])|)
    assert has_element?(view, ~s(input[value="organization"][disabled]))
    assert has_element?(view, ~s(input[aria-label="ORGANIZATION - unsupported by :fast"]))

    assert has_element?(
             view,
             ".entity-capability-note",
             "Unavailable entities are not supported by :fast"
           )

    refute has_element?(view, ~s(input[value="organization"][checked]))
    assert has_element?(view, ~s(input[value="person"][checked]))

    render_change(view, "change_text", %{
      "input" => "Rachel works at Google.",
      "profile" => "accurate",
      "entities" => ["street_address", "organization"],
      "action" => "detect"
    })

    assert has_element?(view, ~s(input[value="street_address"][disabled]))
    refute has_element?(view, ~s(input[value="street_address"][checked]))
    assert has_element?(view, ~s|input[value="organization"]:not([disabled])[checked]|)
  end

  test "offers capability-aware common, all, none, and advanced entity controls", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, ~s(button[phx-value-preset="common"]), "Common")
    refute has_element?(view, "#advanced-entities")

    view |> element(~s(button[phx-value-preset="none"])) |> render_click()
    refute has_element?(view, ~s(input[name="entities[]"][checked]))

    view |> element(~s(button[phx-value-preset="all"])) |> render_click()
    view |> element(~s(button[phx-click="toggle_advanced_entities"])) |> render_click()

    assert has_element?(view, ~s(input[value="street_address"][checked]))
    assert has_element?(view, ~s(input[value="organization"][disabled]))
    refute has_element?(view, ~s(input[value="organization"][checked]))

    view |> element(~s(button[phx-value-preset="common"])) |> render_click()
    assert has_element?(view, ~s(input[value="email"][checked]))
    refute has_element?(view, ~s(input[value="street_address"][checked]))
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
    assert has_element?(view, ".pane-heading h2", "Simulated provider response")
    assert has_element?(view, ".pane-heading span", "No network call")
    assert render(view) =~ "Detection misses and other sensitive data may remain."

    view |> element(~s(button[phx-click="rehydrate_llm"])) |> render_click()
    assert has_element?(view, ".success-stage", "rachel.green@example.com")

    view |> element(~s(button[phx-click="stream_llm"])) |> render_click()
    assert has_element?(view, ".chunk-row code")
    assert has_element?(view, ".success-stage", "rachel.green@example.com")
  end

  test "confirms and reports clearing a populated vault", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view |> element(~s(button[phx-value-tool="vault"])) |> render_click()

    view
    |> form("#vault-workbench form", %{"input" => "Contact rachel.green@example.com"})
    |> render_submit()

    refute has_element?(view, ".confirmation-band")
    view |> element(~s(button[phx-click="request_clear_vault"])) |> render_click()
    assert_push_event(view, "workbench:focus", %{id: "cancel-clear-vault"})

    assert has_element?(
             view,
             ".confirmation-band",
             "Issued pseudonyms will no longer be reversible"
           )

    view |> element(~s(button[phx-click="cancel_clear_vault"])) |> render_click()
    assert_push_event(view, "workbench:focus", %{id: "request-clear-vault"})
    refute has_element?(view, ".confirmation-band")

    view |> element(~s(button[phx-click="request_clear_vault"])) |> render_click()
    view |> element(~s(button[phx-click="clear_vault"])) |> render_click()
    assert_push_event(view, "workbench:focus", %{id: "vault-clear-notice"})

    assert has_element?(view, ".notice-banner", "Vault mappings cleared")
    refute has_element?(view, ~s(button[phx-click="request_clear_vault"]))
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
    assert has_element?(view, ".download-toggle", "Allow model downloads")
    assert has_element?(view, ".prepare-hint", "Unchecked uses cached assets only.")

    assert has_element?(
             view,
             ~s(button.prepare-command[phx-disable-with="Preparing..."]),
             "Prepare"
           )

    refute has_element?(view, ~s(button[title="Prepare profile"]))
    assert render(view) =~ "tner/roberta-large-ontonotes5"
    assert render(view) =~ "Jean-Baptiste/roberta-large-ner-english"
    assert render(view) =~ "about 1.4 GB"
    assert render(view) =~ "Obscura does not bundle or license these model assets"
    assert render(view) =~ "TNER checkpoint licensing is unresolved"
    assert render(view) =~ "not download size"
    assert has_element?(view, ".preflight-state", "Preflight:")
    assert has_element?(view, ".preflight-message")
    assert has_element?(view, ".profile-desktop")
    assert has_element?(view, ".profile-mobile .profile-card")
  end

  test "marks every preparation control disabled while progress is active", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    send(
      view.pid,
      {:profile_progress, :balanced,
       %{status: :loading_model, backend: "binary", allow_download: true}}
    )

    send(view.pid, {:profile_progress, :balanced, %{status: :compiling, backend: :binary}})

    view |> element(~s(button[phx-value-tool="profiles"])) |> render_click()

    assert has_element?(view, ~s(button.prepare-command[data-profile="balanced"][disabled]))

    assert has_element?(
             view,
             ~s(select[aria-label="Backend for :balanced"] option[value="binary"][selected])
           )

    assert has_element?(
             view,
             ~s(input[aria-label="Allow model downloads for :balanced"][checked])
           )

    assert has_element?(view, ~s(form[aria-busy="true"]))
    assert has_element?(view, ~s(button[phx-click="cancel_preparation"]), "Cancel preparation")

    render_submit(view, "prepare_profile", %{
      "profile" => "balanced",
      "backend" => "binary"
    })

    assert has_element?(view, ".runtime-state", "Compiling")

    view
    |> element(
      ~s(.profile-desktop button[phx-click="cancel_preparation"][phx-value-profile="balanced"])
    )
    |> render_click()

    send(view.pid, {:profile_progress, :balanced, %{status: :loading_model, backend: :emily}})

    assert has_element?(view, ".runtime-state", "Preparation cancelled")
    assert has_element?(view, ~s(form[aria-busy="false"]))
    assert has_element?(view, ~s|button.prepare-command[data-profile="balanced"]:not([disabled])|)
  end

  test "documents the local Plug endpoint and exposes a copy control", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    view |> element(~s(button[phx-value-tool="logger"])) |> render_click()

    assert has_element?(view, ".api-band strong", "Local Plug endpoint")
    assert has_element?(view, ~s(#copy-plug-curl[phx-hook="CopyToClipboard"]), "Copy curl")
    assert has_element?(view, "#plug-curl", "localhost:4000/api/redact")
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
