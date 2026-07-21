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
        operators: Demo.operators(),
        backend_options: backend_options(),
        profile_rows: Demo.profile_rows(),
        runtimes: %{},
        preparation: %{},
        vault: nil,
        text_params: %{
          "input" => @default_text,
          "profile" => "fast",
          "entities" => @default_entities,
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
    {:noreply, assign(socket, :active_tool, selected)}
  end

  def handle_event("change_text", params, socket) do
    params =
      params
      |> Map.put_new("operator", socket.assigns.text_params["operator"])
      |> filter_supported_entities()

    {:noreply, assign(socket, :text_params, params)}
  end

  def handle_event("run_text", params, socket) do
    socket = maybe_start_vault(socket)

    if unprepared_profile?(params["profile"], socket.assigns.runtimes) do
      profile = params["profile"]

      {:noreply,
       socket
       |> assign(:active_tool, :profiles)
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

  def handle_event("clear_vault", _params, socket) do
    case Obscura.Vault.clear(socket.assigns.vault) do
      :ok ->
        {:noreply,
         assign(socket,
           llm_safe: nil,
           llm_response: nil,
           llm_rehydrated: nil,
           stream_chunks: [],
           llm_error: nil
         )}

      {:error, reason} ->
        {:noreply, assign(socket, llm_error: Demo.error_message(reason))}
    end
  end

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
         {:ok, backend} <- parse_backend(params["backend"]) do
      owner = self()
      allow_download = params["allow_download"] == "true"

      socket =
        socket
        |> assign_preparation(profile, %{status: :starting, message: "Starting preparation"})
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
      {:error, message} -> {:noreply, put_flash(socket, :error, message)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:profile_progress, profile, event}, socket) do
    status = Map.get(event, :status, Map.get(event, :stage, :working))
    message = status |> to_string() |> String.replace("_", " ") |> String.capitalize()

    {:noreply,
     assign_preparation(socket, profile, %{
       status: :working,
       message: message,
       bytes: Map.get(event, :observed_bytes, Map.get(event, :downloaded_bytes))
     })}
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
    {:noreply,
     assign_preparation(socket, profile, %{
       status: :error,
       message: "Preparation process stopped unexpectedly."
     })}
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
    assign(socket, :preparation, Map.put(socket.assigns.preparation, profile, state))
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

  defp entity_supported?(profile, entity), do: entity in Demo.supported_entities(profile)

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
end
