defmodule ObscuraExamples.Demo do
  @moduledoc """
  Stable Obscura workflows used by the web example and its contract tests.
  """

  alias Obscura.Anonymizer.Error
  alias Obscura.Capabilities
  alias Obscura.Diagnostic

  @profiles [:fast, :balanced, :accurate]
  @common_entities [
    :email,
    :phone,
    :person,
    :location,
    :organization,
    :credit_card,
    :us_ssn,
    :domain
  ]
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
    :street_address,
    :date_time,
    :title
  ]
  @operators ~w(replace redact mask hash pseudonymize)
  @model_metadata %{
    tner_roberta_large_ontonotes5: %{
      name: "tner/roberta-large-ontonotes5",
      source: "https://huggingface.co/tner/roberta-large-ontonotes5"
    },
    jean_baptiste_roberta_large_ner_english: %{
      name: "Jean-Baptiste/roberta-large-ner-english",
      source: "https://huggingface.co/Jean-Baptiste/roberta-large-ner-english"
    }
  }
  @profile_cache_estimates %{
    balanced: "about 1.4 GB",
    accurate: "about 2.8 GB"
  }
  @licensing_guide_url "https://hexdocs.pm/obscura/model-asset-licensing.html"

  @spec profiles() :: [atom()]
  def profiles, do: @profiles

  @spec entities() :: [atom()]
  def entities, do: @entities

  @spec common_entities() :: [atom()]
  def common_entities, do: @common_entities

  @spec advanced_entities() :: [atom()]
  def advanced_entities, do: @entities -- @common_entities

  @spec supported_entities(atom() | String.t()) :: [atom()]
  def supported_entities(profile) when is_binary(profile) do
    case Enum.find(@profiles, &(Atom.to_string(&1) == profile)) do
      nil -> []
      profile -> supported_entities(profile)
    end
  end

  def supported_entities(profile) when profile in @profiles do
    {:ok, descriptor} = Obscura.Profile.fetch(profile)
    descriptor.supported_entities
  end

  def supported_entities(_profile), do: []

  @spec operators() :: [String.t()]
  def operators, do: @operators

  @spec run_text(map(), map(), GenServer.server() | nil) ::
          {:ok, map()} | {:error, String.t()}
  def run_text(params, runtimes, vault) do
    with {:ok, input} <- input(params),
         {:ok, profile} <- profile(params),
         :ok <- require_runtime(profile, runtimes),
         {:ok, entities} <- selected_entities(params),
         :ok <- validate_supported_entities(profile, entities),
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
         {:ok, entities} <- selected_entities(params),
         :ok <- validate_supported_entities(profile, entities) do
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
         {:ok, entities} <- selected_entities(params),
         :ok <- validate_supported_entities(profile, entities) do
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

  @spec profile_rows(module()) :: [map()]
  def profile_rows(capabilities \\ Capabilities) do
    Enum.map(@profiles, fn profile ->
      {:ok, descriptor} = Obscura.Profile.describe(profile)

      readiness =
        case Obscura.Profile.preflight(profile) do
          {:ok, report} ->
            %{status: :ready, report: report, message: "Preflight passed."}

          {:error, diagnostic, report} ->
            %{
              status: :unavailable,
              report: report,
              error: diagnostic,
              message: Diagnostic.format(diagnostic)
            }
        end

      %{
        name: profile,
        descriptor: descriptor,
        readiness: readiness,
        preparation: preparation_details(profile, descriptor, capabilities)
      }
    end)
  end

  @doc false
  @spec asset_license_notices(atom(), module()) :: [map()]
  def asset_license_notices(:fast, _capabilities), do: []

  def asset_license_notices(profile, capabilities) do
    case capabilities.assets_for_profile(profile) do
      {:ok, []} -> [unavailable_license_notice("profile_assets_not_reported")]
      {:ok, assets} -> Enum.map(assets, &asset_license_notice/1)
      {:error, _reason} -> [unavailable_license_notice("capability_lookup_failed")]
    end
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

  defp validate_supported_entities(profile, entities) do
    unsupported = entities -- supported_entities(profile)

    if unsupported == [] do
      :ok
    else
      names = Enum.map_join(unsupported, ", ", &Atom.to_string/1)
      {:error, "Unsupported for :#{profile}: #{names}."}
    end
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
      {:error, %Jason.DecodeError{} = error} -> {:error, json_error(source, error)}
    end
  end

  defp preparation_details(profile, descriptor, capabilities) do
    %{
      models: Enum.map(descriptor.default_models, &Map.fetch!(@model_metadata, &1)),
      approximate_cache_size: Map.get(@profile_cache_estimates, profile, "No model assets"),
      cache_destination: bumblebee_cache_destination(),
      backend_guidance: backend_guidance(descriptor.backend_policy),
      license_notices: asset_license_notices(profile, capabilities)
    }
  end

  defp asset_license_notice(
         %{"id" => id, "commercial_use" => "requires_ldc_for_profit_membership"} = asset
       ) do
    model = Map.get(asset, "model_repository", id)

    %{
      asset: id,
      status: :restricted,
      commercial_use: "requires_ldc_for_profit_membership",
      title: "Commercial use requires LDC membership",
      message:
        "LDC confirmed that commercial use of #{model} requires an LDC for-profit membership. Obscura does not grant or verify that authorization.",
      documentation_url: @licensing_guide_url,
      source_url: ldc_agreement_url(asset)
    }
  end

  defp asset_license_notice(%{"id" => id, "commercial_use" => commercial_use}) do
    %{
      asset: id,
      status: :review,
      commercial_use: commercial_use,
      title: "External model terms require review",
      message:
        "Obscura reports #{commercial_use_label(commercial_use)} for this asset. Stable profile status is not commercial-use clearance.",
      documentation_url: @licensing_guide_url,
      source_url: nil
    }
  end

  defp asset_license_notice(%{"id" => id}) do
    unavailable_license_notice(id)
  end

  defp asset_license_notice(_asset), do: unavailable_license_notice("unknown_asset")

  defp unavailable_license_notice(asset) do
    %{
      asset: asset,
      status: :unknown,
      commercial_use: "not_reported",
      title: "Commercial-use status unavailable",
      message:
        "The installed Obscura version does not report commercial-use metadata for this model asset. Do not assume commercial clearance; review the current Obscura licensing guide before preparation.",
      documentation_url: @licensing_guide_url,
      source_url: nil
    }
  end

  defp commercial_use_label(commercial_use) do
    commercial_use
    |> String.replace("_", " ")
  end

  defp ldc_agreement_url(asset) do
    asset
    |> Map.get("license_sources", [])
    |> Enum.find(&String.contains?(&1, "ldc-non-members-agreement.pdf"))
  end

  defp bumblebee_cache_destination do
    System.get_env("BUMBLEBEE_CACHE_DIR") ||
      :filename.basedir(:user_cache, "bumblebee") |> to_string()
  end

  defp backend_guidance(:none), do: "No model backend required."

  defp backend_guidance(:explicit) do
    "Emily uses the Apple Silicon Metal GPU; Binary is the portable CPU path."
  end

  defp json_error(source, %Jason.DecodeError{position: position}) do
    {line, column} = json_location(source, position)

    "Invalid JSON at line #{line}, column #{column} (byte #{position}). " <>
      "Check commas, quotes, and closing braces near that location."
  end

  defp json_location(source, position) do
    position = min(max(position, 0), byte_size(source))
    prefix = binary_part(source, 0, position)
    newlines = :binary.matches(prefix, "\n")

    line_start =
      case List.last(newlines) do
        nil -> 0
        {index, 1} -> index + 1
      end

    {length(newlines) + 1, position - line_start + 1}
  end

  defp humanize(value) do
    value
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
