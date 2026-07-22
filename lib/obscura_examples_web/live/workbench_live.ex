defmodule ObscuraExamplesWeb.WorkbenchLive do
  use ObscuraExamplesWeb, :live_view

  alias ObscuraExamples.Demo

  @default_entities ~w(email phone credit_card us_ssn iban ip_address url domain)
  @default_text "Rachel works at Google in Paris. Contact her at info@example.com or +1 202-555-0188. Visit example.org. Card 4111 1111 1111 1111."
  @default_structured Jason.encode!(
                        %{
                          "customer" => %{
                            "email" => "rachel.green@example.com",
                            "phone" => "+1 202-555-0188",
                            "password" => "synthetic-secret"
                          },
                          "api_key" => "demo-only-key"
                        },
                        pretty: true
                      )
  @default_logger Jason.encode!(
                    %{
                      "request_id" => "demo-42",
                      "user" => "rachel.green@example.com",
                      "phone" => "+1 202-555-0188"
                    },
                    pretty: true
                  )

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Obscura Workbench",
        active_tool: :text,
        profiles: Demo.profiles(),
        entities: Demo.entities(),
        common_entities: Demo.common_entities(),
        advanced_entities: Demo.advanced_entities(),
        entities_expanded: false,
        operators: Demo.operators(),
        backend_options: backend_options(),
        profile_rows: Demo.profile_rows(),
        runtimes: %{},
        preparation: %{},
        vault: nil,
        text_params: %{
          "input" => @default_text,
          "profile" => "fast",
          "entities" =>
            Demo.common_entities()
            |> Enum.filter(&(&1 in Demo.supported_entities(:fast)))
            |> Enum.map(&Atom.to_string/1),
          "action" => "detect",
          "operator" => "replace"
        },
        text_result: nil,
        text_error: nil,
        structured_params: %{
          "input" => @default_structured,
          "profile" => "fast",
          "entities" => @default_entities
        },
        structured_result: nil,
        structured_error: nil,
        llm_input: "Please send the appointment details to rachel.green@example.com.",
        llm_safe: nil,
        llm_response: nil,
        llm_rehydrated: nil,
        llm_error: nil,
        vault_clear_pending: false,
        vault_notice: nil,
        stream_chunks: [],
        logger_params: %{
          "input" => @default_logger,
          "profile" => "fast",
          "entities" => @default_entities
        },
        logger_result: nil,
        logger_error: nil
      )

    {:ok, maybe_start_vault(socket)}
  end

  @impl Phoenix.LiveView
  def handle_event("select_tool", %{"tool" => tool}, socket) do
    allowed = ~w(text structured vault logger profiles)
    selected = if tool in allowed, do: String.to_existing_atom(tool), else: :text

    {:noreply,
     socket
     |> assign(:active_tool, selected)
     |> push_event("workbench:selected", %{id: "#{selected}-workbench"})}
  end

  def handle_event("change_text", params, socket) do
    params =
      params
      |> Map.put_new("operator", socket.assigns.text_params["operator"])
      |> filter_supported_entities()

    {:noreply,
     assign(socket,
       text_params: params,
       text_result: nil,
       text_error: nil
     )}
  end

  def handle_event("select_entity_preset", %{"preset" => preset}, socket) do
    supported = Demo.supported_entities(socket.assigns.text_params["profile"])

    selected =
      case preset do
        "common" -> Enum.filter(Demo.common_entities(), &(&1 in supported))
        "all" -> Enum.filter(Demo.entities(), &(&1 in supported))
        "none" -> []
        _other -> selected_entity_atoms(socket.assigns.text_params)
      end

    params = Map.put(socket.assigns.text_params, "entities", Enum.map(selected, &to_string/1))

    {:noreply,
     assign(socket,
       text_params: params,
       text_result: nil,
       text_error: nil
     )}
  end

  def handle_event("toggle_advanced_entities", _params, socket) do
    {:noreply, update(socket, :entities_expanded, &(!&1))}
  end

  def handle_event("run_text", params, socket) do
    socket = maybe_start_vault(socket)

    if unprepared_profile?(params["profile"], socket.assigns.runtimes) do
      profile = params["profile"]

      {:noreply,
       socket
       |> assign(:active_tool, :profiles)
       |> push_event("workbench:selected", %{id: "profiles-workbench"})
       |> put_flash(:error, "Prepare :#{profile} before running inference.")}
    else
      run_text(params, socket)
    end
  end

  def handle_event("run_structured", params, socket) do
    case Demo.run_structured(params, socket.assigns.runtimes) do
      {:ok, result} ->
        {:noreply,
         assign(socket,
           structured_params: params,
           structured_result: result,
           structured_error: nil
         )}

      {:error, message} ->
        {:noreply,
         assign(socket,
           structured_params: params,
           structured_result: nil,
           structured_error: message
         )}
    end
  end

  def handle_event("redact_llm", %{"input" => input}, socket) do
    socket = maybe_start_vault(socket)
    messages = [%{role: :system, content: "Be concise."}, %{role: :user, content: input}]

    case Obscura.LLM.redact_messages(messages,
           vault: socket.assigns.vault,
           profile: :fast,
           entities: [:email, :phone]
         ) do
      {:ok, safe_messages, _vault} ->
        safe = safe_messages |> List.last() |> Map.fetch!(:content)
        response = "Confirmed. I will use #{safe}"

        {:noreply,
         assign(socket,
           llm_input: input,
           llm_safe: safe,
           llm_response: response,
           llm_rehydrated: nil,
           llm_error: nil,
           vault_clear_pending: false,
           vault_notice: nil,
           stream_chunks: []
         )}

      {:error, reason} ->
        {:noreply, assign(socket, llm_error: Demo.error_message(reason))}
    end
  end

  def handle_event("rehydrate_llm", _params, socket) do
    case Obscura.LLM.rehydrate_response(socket.assigns.llm_response || "",
           vault: socket.assigns.vault
         ) do
      {:ok, response} -> {:noreply, assign(socket, llm_rehydrated: response, llm_error: nil)}
      {:error, reason} -> {:noreply, assign(socket, llm_error: Demo.error_message(reason))}
    end
  end

  def handle_event("stream_llm", _params, socket) do
    response = socket.assigns.llm_response || ""
    split_at = max(div(byte_size(response), 2), 1)
    <<first::binary-size(^split_at), second::binary>> = response

    result =
      with {:ok, stream} <- Obscura.Stream.Rehydrator.new(vault: socket.assigns.vault),
           {:ok, ready1, stream} <- Obscura.Stream.Rehydrator.feed(stream, first),
           {:ok, ready2, stream} <- Obscura.Stream.Rehydrator.feed(stream, second),
           {:ok, rest} <- Obscura.Stream.Rehydrator.flush(stream) do
        {:ok, [ready1, ready2, rest], ready1 <> ready2 <> rest}
      end

    case result do
      {:ok, chunks, output} ->
        {:noreply,
         assign(socket,
           stream_chunks: chunks,
           llm_rehydrated: output,
           llm_error: nil
         )}

      {:error, reason} ->
        {:noreply, assign(socket, llm_error: Demo.error_message(reason))}
    end
  end

  def handle_event("request_clear_vault", _params, socket) do
    {:noreply,
     socket
     |> assign(vault_clear_pending: true, vault_notice: nil)
     |> push_event("workbench:focus", %{id: "cancel-clear-vault"})}
  end

  def handle_event("cancel_clear_vault", _params, socket) do
    {:noreply,
     socket
     |> assign(:vault_clear_pending, false)
     |> push_event("workbench:focus", %{id: "request-clear-vault"})}
  end

  def handle_event("clear_vault", _params, %{assigns: %{vault_clear_pending: true}} = socket) do
    case Obscura.Vault.clear(socket.assigns.vault) do
      :ok ->
        {:noreply,
         socket
         |> assign(
           llm_safe: nil,
           llm_response: nil,
           llm_rehydrated: nil,
           stream_chunks: [],
           llm_error: nil,
           vault_clear_pending: false,
           vault_notice:
             "Vault mappings cleared. Previously issued tokens cannot be rehydrated in this session."
         )
         |> push_event("workbench:focus", %{id: "vault-clear-notice"})}

      {:error, reason} ->
        {:noreply, assign(socket, llm_error: Demo.error_message(reason))}
    end
  end

  def handle_event("clear_vault", _params, socket), do: {:noreply, socket}

  def handle_event("run_logger", params, socket) do
    case Demo.run_logger(params, socket.assigns.runtimes) do
      {:ok, result} ->
        {:noreply,
         assign(socket, logger_params: params, logger_result: result, logger_error: nil)}

      {:error, message} ->
        {:noreply,
         assign(socket, logger_params: params, logger_result: nil, logger_error: message)}
    end
  end

  def handle_event("prepare_profile", params, socket) do
    with {:ok, profile} <- parse_profile(params["profile"]),
         {:ok, backend} <- parse_backend(params["backend"]),
         :ok <- ensure_preparation_idle(socket.assigns.preparation, profile) do
      owner = self()
      allow_download = params["allow_download"] == "true"

      socket =
        socket
        |> assign_preparation(profile, %{
          status: :starting,
          message: "Starting preparation",
          backend: Atom.to_string(backend),
          allow_download: allow_download
        })
        |> start_async({:prepare, profile}, fn ->
          Obscura.Profile.prepare(profile,
            allow_download: allow_download,
            real_model_backend: backend,
            emily_device: :gpu,
            emily_fallback: :raise,
            compile: [batch_size: 1, sequence_length: 128],
            progress: fn event -> send(owner, {:profile_progress, profile, event}) end
          )
        end)

      {:noreply, socket}
    else
      {:error, :already_preparing} -> {:noreply, socket}
      {:error, message} -> {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("cancel_preparation", %{"profile" => profile_name}, socket) do
    with {:ok, profile} <- parse_profile(profile_name),
         true <-
           preparation_for(socket.assigns.preparation, profile).status in [:starting, :working] do
      {:noreply,
       socket
       |> cancel_async({:prepare, profile})
       |> assign_preparation(profile, %{status: :cancelled, message: "Preparation cancelled"})}
    else
      _other -> {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:profile_progress, profile, event}, socket) do
    if preparation_for(socket.assigns.preparation, profile).status == :cancelled do
      {:noreply, socket}
    else
      status = Map.get(event, :status, Map.get(event, :stage, :working))
      message = status |> to_string() |> String.replace("_", " ") |> String.capitalize()

      state =
        event
        |> Map.take([:backend, :allow_download])
        |> normalize_preparation_state()
        |> Map.merge(%{
          status: :working,
          message: message,
          bytes: Map.get(event, :observed_bytes, Map.get(event, :downloaded_bytes))
        })

      {:noreply, assign_preparation(socket, profile, state)}
    end
  end

  @impl Phoenix.LiveView
  def handle_async({:prepare, profile}, {:ok, {:ok, runtime}}, socket) do
    runtimes = Map.put(socket.assigns.runtimes, profile, runtime)

    {:noreply,
     socket
     |> assign(:runtimes, runtimes)
     |> assign_preparation(profile, %{status: :ready, message: "Runtime ready"})}
  end

  def handle_async({:prepare, profile}, {:ok, {:error, reason}}, socket) do
    {:noreply,
     assign_preparation(socket, profile, %{
       status: :error,
       message: Demo.error_message(reason)
     })}
  end

  def handle_async({:prepare, profile}, {:exit, _reason}, socket) do
    if preparation_for(socket.assigns.preparation, profile).status == :cancelled do
      {:noreply, socket}
    else
      {:noreply,
       assign_preparation(socket, profile, %{
         status: :error,
         message: "Preparation process stopped unexpectedly."
       })}
    end
  end

  defp run_text(params, socket) do
    case Demo.run_text(params, socket.assigns.runtimes, socket.assigns.vault) do
      {:ok, result} ->
        {:noreply,
         assign(socket,
           text_params: params,
           text_result: result,
           text_error: nil
         )}

      {:error, message} ->
        {:noreply,
         assign(socket,
           text_params: params,
           text_result: nil,
           text_error: message
         )}
    end
  end

  defp maybe_start_vault(%{assigns: %{vault: vault}} = socket) when is_pid(vault) do
    if Process.alive?(vault), do: socket, else: start_vault(socket)
  end

  defp maybe_start_vault(socket), do: start_vault(socket)

  defp start_vault(socket) do
    if connected?(socket) do
      case Obscura.Vault.Memory.start_link() do
        {:ok, vault} -> assign(socket, :vault, vault)
        {:error, _reason} -> socket
      end
    else
      socket
    end
  end

  defp assign_preparation(socket, profile, state) do
    previous = Map.get(socket.assigns.preparation, profile, %{})
    updated = Map.merge(previous, state)
    assign(socket, :preparation, Map.put(socket.assigns.preparation, profile, updated))
  end

  defp parse_profile(profile) do
    case Enum.find(Demo.profiles(), &(Atom.to_string(&1) == profile)) do
      nil -> {:error, "Unknown profile."}
      value -> {:ok, value}
    end
  end

  defp parse_backend("emily"), do: {:ok, :emily}
  defp parse_backend("binary"), do: {:ok, :binary}
  defp parse_backend(_backend), do: {:error, "Unknown backend."}

  defp selected?(params, entity), do: Atom.to_string(entity) in Map.get(params, "entities", [])

  defp selected_entity_atoms(params) do
    selected = Map.get(params, "entities", [])
    Enum.filter(Demo.entities(), &(Atom.to_string(&1) in selected))
  end

  defp advanced_selection_count(params) do
    params
    |> selected_entity_atoms()
    |> Enum.count(&(&1 in Demo.advanced_entities()))
  end

  defp entity_supported?(profile, entity), do: entity in Demo.supported_entities(profile)

  defp entity_accessible_label(profile, entity) do
    label = display_entity(entity)

    if entity_supported?(profile, entity),
      do: label,
      else: "#{label} - unsupported by :#{profile}"
  end

  defp unsupported_entities?(profile) do
    Enum.any?(Demo.entities(), &(!entity_supported?(profile, &1)))
  end

  defp filter_supported_entities(params) do
    supported = params["profile"] |> Demo.supported_entities() |> Enum.map(&Atom.to_string/1)
    selected = params |> Map.get("entities", []) |> Enum.filter(&(&1 in supported))
    Map.put(params, "entities", selected)
  end

  defp display_entity(entity) do
    entity |> Atom.to_string() |> String.replace("_", " ") |> String.upcase()
  end

  defp format_score(score) when is_float(score), do: :erlang.float_to_binary(score, decimals: 3)
  defp format_score(_score), do: "-"

  defp result_heading(%{kind: :analysis}), do: "Detection result"
  defp result_heading(%{kind: :anonymization}), do: "Anonymized text"

  defp result_count(%{kind: :analysis, item_count: count}),
    do: count_label(count, "detection")

  defp result_count(%{kind: :anonymization, item_count: count}),
    do: count_label(count, "replacement")

  defp result_summary(%{kind: :analysis, item_count: count}) do
    "Detection complete: #{count_label(count, "entity", "entities")} found. Results follow."
  end

  defp result_summary(%{kind: :anonymization, item_count: count}) do
    "Anonymization complete: #{count_label(count, "replacement")} applied. Results follow."
  end

  defp count_label(1, noun), do: "1 #{noun}"
  defp count_label(count, noun), do: "#{count} #{noun}s"
  defp count_label(1, singular, _plural), do: "1 #{singular}"
  defp count_label(count, _singular, plural), do: "#{count} #{plural}"

  defp display_list([]), do: "None"
  defp display_list(items), do: Enum.map_join(items, ", ", &to_string/1)

  defp profile_state_message(:fast, _state, _runtimes), do: "Ready - no model runtime required"

  defp profile_state_message(profile, state, runtimes) do
    if runtime_ready?(runtimes, profile),
      do: "Ready - reusable runtime loaded",
      else: state.message
  end

  defp backend_selected?(state, value), do: state[:backend] == value

  defp normalize_preparation_state(%{backend: backend} = state) when is_atom(backend),
    do: %{state | backend: Atom.to_string(backend)}

  defp normalize_preparation_state(state), do: state

  defp asset_size_label(%{models: []}), do: "No model assets"

  defp asset_size_label(preparation) do
    "Approx. cache footprint: #{preparation.approximate_cache_size}; not download size"
  end

  defp vault_populated?(assigns),
    do: not is_nil(assigns.llm_safe) or not is_nil(assigns.llm_response)

  defp runtime_ready?(runtimes, profile), do: Map.has_key?(runtimes, profile)

  defp unprepared_profile?(profile, runtimes) when is_binary(profile) do
    case Enum.find(Demo.profiles(), &(Atom.to_string(&1) == profile)) do
      nil -> false
      :fast -> false
      selected -> not runtime_ready?(runtimes, selected)
    end
  end

  defp unprepared_profile?(_profile, _runtimes), do: false

  defp backend_options do
    if Code.ensure_loaded?(Emily) and Code.ensure_loaded?(Emily.Backend) do
      [{"Emily GPU", "emily"}, {"Binary", "binary"}]
    else
      [{"Binary", "binary"}]
    end
  end

  defp preparation_for(preparation, profile) do
    Map.get(preparation, profile, %{status: :idle, message: "Not prepared"})
  end

  defp ensure_preparation_idle(preparation, profile) do
    if preparation_for(preparation, profile).status in [:starting, :working] do
      {:error, :already_preparing}
    else
      :ok
    end
  end
end
