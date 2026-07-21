defmodule ObscuraExamples.Demo do
  @moduledoc """
  Stable Obscura workflows used by the web example and its contract tests.
  """

  alias Obscura.Anonymizer.Error
  alias Obscura.Diagnostic

  @profiles [:fast, :balanced, :accurate]
  @entities [
    :email,
    :phone,
    :credit_card,
    :us_ssn,
    :iban,
    :ip_address,
    :url,
    :domain,
    :person,
    :location,
    :organization,
    :address,
    :date_time,
    :title
  ]
  @operators ~w(replace redact mask hash pseudonymize)

  @spec profiles() :: [atom()]
  def profiles, do: @profiles

  @spec entities() :: [atom()]
  def entities, do: @entities

  @spec operators() :: [String.t()]
  def operators, do: @operators

  @spec run_text(map(), map(), GenServer.server() | nil) ::
          {:ok, map()} | {:error, String.t()}
  def run_text(params, runtimes, vault) do
    with {:ok, input} <- input(params),
         {:ok, profile} <- profile(params),
         :ok <- require_runtime(profile, runtimes),
         {:ok, entities} <- selected_entities(params),
         {:ok, action} <- text_action(params) do
      profile_ref = Map.get(runtimes, profile, profile)
      opts = [profile: profile_ref, entities: entities, explain: true, include_text: true]

      case action do
        :detect -> analyze(input, opts)
        :anonymize -> anonymize(input, opts, params, vault)
      end
    end
  end

  @spec run_structured(map(), map()) :: {:ok, map()} | {:error, String.t()}
  def run_structured(params, runtimes) do
    with {:ok, source} <- input(params),
         {:ok, data} <- decode_json(source),
         {:ok, profile} <- profile(params),
         :ok <- require_runtime(profile, runtimes),
         {:ok, entities} <- selected_entities(params) do
      profile_ref = Map.get(runtimes, profile, profile)

      case Obscura.Structured.redact(data,
             profile: profile_ref,
             entities: entities,
             field_policies: %{"password" => :drop, "api_key" => {:replace, "[SECRET]"}}
           ) do
        {:ok, result} ->
          {:ok,
           %{
             output: Jason.encode!(result.data, pretty: true),
             item_count: length(result.items),
             status: result.status
           }}

        {:error, reason} ->
          {:error, error_message(reason)}
      end
    end
  end

  @spec run_logger(map(), map()) :: {:ok, map()} | {:error, String.t()}
  def run_logger(params, runtimes) do
    with {:ok, source} <- input(params),
         {:ok, data} <- decode_json(source),
         {:ok, profile} <- profile(params),
         :ok <- require_runtime(profile, runtimes),
         {:ok, entities} <- selected_entities(params) do
      profile_ref = Map.get(runtimes, profile, profile)
      opts = [profile: profile_ref, entities: entities]

      with {:ok, redacted} <- Obscura.Logger.redact_term(data, opts),
           {:ok, inspected} <- Obscura.Logger.safe_inspect(data, opts) do
        {:ok, %{output: Jason.encode!(redacted, pretty: true), inspected: inspected}}
      else
        {:error, reason} -> {:error, error_message(reason)}
      end
    end
  end

  @spec profile_rows() :: [map()]
  def profile_rows do
    Enum.map(@profiles, fn profile ->
      {:ok, descriptor} = Obscura.Profile.describe(profile)

      readiness =
        case Obscura.Profile.preflight(profile) do
          {:ok, report} ->
            %{status: :ready, report: report}

          {:error, diagnostic, report} ->
            %{status: :unavailable, report: report, error: diagnostic}
        end

      %{name: profile, descriptor: descriptor, readiness: readiness}
    end)
  end

  @spec error_message(term()) :: String.t()
  def error_message(%Diagnostic{} = diagnostic), do: Diagnostic.format(diagnostic)
  def error_message(%Error{} = error), do: Exception.message(error)
  def error_message(reason) when is_atom(reason), do: reason |> Atom.to_string() |> humanize()

  def error_message({reason, _details}) when is_atom(reason),
    do: reason |> Atom.to_string() |> humanize()

  def error_message(_reason), do: "The operation could not be completed."

  defp analyze(input, opts) do
    case Obscura.analyze(input, opts) do
      {:ok, results} ->
        {:ok,
         %{
           kind: :analysis,
           output: input,
           matches: Enum.map(results, &match_row/1),
           item_count: length(results)
         }}

      {:error, reason} ->
        {:error, error_message(reason)}
    end
  end

  defp anonymize(input, opts, params, vault) do
    with {:ok, operator} <- operator(params),
         :ok <- require_vault(operator, vault) do
      redact_opts =
        opts ++
          [operators: %{default: operator_config(operator)}, vault: vault]

      case Obscura.redact(input, redact_opts) do
        {:ok, result} ->
          {:ok,
           %{
             kind: :anonymization,
             output: result.text,
             matches: Enum.map(result.items, &item_row/1),
             item_count: length(result.items),
             status: result.status
           }}

        {:error, reason} ->
          {:error, error_message(reason)}
      end
    end
  end

  defp match_row(result) do
    %{
      entity: result.entity,
      text: result.text,
      byte_start: result.byte_start,
      byte_end: result.byte_end,
      score: result.score,
      recognizer: result.recognizer
    }
  end

  defp item_row(item) do
    %{
      entity: item.entity,
      operator: item.operator,
      byte_start: item.source_byte_start,
      byte_end: item.source_byte_end,
      replacement: item.replacement
    }
  end

  defp input(params) do
    case Map.get(params, "input") do
      input when is_binary(input) and byte_size(input) <= 50_000 -> {:ok, input}
      input when is_binary(input) -> {:error, "Input exceeds the 50 KB example limit."}
      _other -> {:error, "Input must be text."}
    end
  end

  defp profile(params) do
    profile = params |> Map.get("profile", "fast") |> to_string()

    case Enum.find(@profiles, &(Atom.to_string(&1) == profile)) do
      nil -> {:error, "Unknown profile."}
      selected -> {:ok, selected}
    end
  end

  defp require_runtime(:fast, _runtimes), do: :ok

  defp require_runtime(profile, runtimes) do
    if Map.has_key?(runtimes, profile) do
      :ok
    else
      {:error, "Prepare :#{profile} in Profiles before running inference."}
    end
  end

  defp selected_entities(params) do
    selected = Map.get(params, "entities", [])
    selected = if is_list(selected), do: selected, else: [selected]

    entities =
      Enum.flat_map(selected, fn value ->
        case Enum.find(@entities, &(Atom.to_string(&1) == to_string(value))) do
          nil -> []
          entity -> [entity]
        end
      end)

    if entities == [], do: {:error, "Select at least one entity."}, else: {:ok, entities}
  end

  defp text_action(params) do
    case Map.get(params, "action", "detect") do
      "detect" -> {:ok, :detect}
      "anonymize" -> {:ok, :anonymize}
      _other -> {:error, "Unknown text action."}
    end
  end

  defp operator(params) do
    case Map.get(params, "operator", "replace") do
      operator when operator in @operators -> {:ok, operator}
      _other -> {:error, "Unknown operator."}
    end
  end

  defp operator_config("replace"), do: %{type: :replace}
  defp operator_config("redact"), do: %{type: :redact}
  defp operator_config("mask"), do: %{type: :mask, char: "*", keep_last: 4}
  defp operator_config("hash"), do: %{type: :hash, mode: :secure, algorithm: :sha256}
  defp operator_config("pseudonymize"), do: %{type: :pseudonymize}

  defp require_vault("pseudonymize", nil), do: {:error, "The session vault is unavailable."}
  defp require_vault(_operator, _vault), do: :ok

  defp decode_json(source) do
    case Jason.decode(source) do
      {:ok, data} when is_map(data) or is_list(data) -> {:ok, data}
      {:ok, _data} -> {:error, "JSON input must be an object or array."}
      {:error, _reason} -> {:error, "Input is not valid JSON."}
    end
  end

  defp humanize(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
