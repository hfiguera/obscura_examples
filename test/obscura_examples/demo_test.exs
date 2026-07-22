defmodule ObscuraExamples.DemoTest do
  use ExUnit.Case, async: true

  alias ObscuraExamples.Demo

  setup do
    start_supervised!(Obscura.Vault.Memory)
    |> then(&{:ok, vault: &1})
  end

  test "detects deterministic PII through the fast profile", %{vault: vault} do
    params = text_params("detect", "replace")

    assert {:ok, result} = Demo.run_text(params, %{}, vault)
    assert result.kind == :analysis
    assert Enum.map(result.matches, & &1.entity) == [:email, :phone]

    assert Enum.map(result.matches, & &1.text) == [
             "rachel.green@example.com",
             "+1 202-555-0188"
           ]
  end

  test "runs every stable anonymization operator", %{vault: vault} do
    for operator <- Demo.operators() do
      assert {:ok, result} = Demo.run_text(text_params("anonymize", operator), %{}, vault)
      assert result.kind == :anonymization
      assert result.item_count == 2
      refute result.output == text_params("anonymize", operator)["input"]
    end
  end

  test "redacts structured JSON and drops sensitive fields" do
    params = %{
      "input" =>
        Jason.encode!(%{
          "email" => "rachel.green@example.com",
          "password" => "synthetic-secret"
        }),
      "profile" => "fast",
      "entities" => ["email"]
    }

    assert {:ok, result} = Demo.run_structured(params, %{})
    assert Jason.decode!(result.output) == %{"email" => "[EMAIL]"}
    assert result.item_count == 2
  end

  test "produces redacted Logger data and safe inspection" do
    params = %{
      "input" => Jason.encode!(%{"user" => "rachel.green@example.com"}),
      "profile" => "fast",
      "entities" => ["email"]
    }

    assert {:ok, result} = Demo.run_logger(params, %{})
    assert Jason.decode!(result.output) == %{"user" => "[EMAIL]"}
    assert result.inspected == ~s(%{"user" => "[EMAIL]"})
  end

  test "reports malformed JSON with a structured line and column" do
    params = %{
      "input" => "{\n  \"email\": \"rachel@example.com\",\n  \"phone\": }",
      "profile" => "fast",
      "entities" => ["email"]
    }

    assert {:error, message} = Demo.run_structured(params, %{})
    assert message =~ "Invalid JSON at line 3, column 12"
    assert message =~ "Check commas, quotes, and closing braces"
  end

  test "exposes only the stable product profile set" do
    assert Demo.profiles() == Obscura.Profile.names()
    assert Demo.profiles() == [:fast, :balanced, :accurate]
  end

  test "exposes canonical entities and profile-specific capabilities" do
    assert :street_address in Demo.entities()
    refute :address in Demo.entities()

    assert :street_address in Demo.supported_entities(:fast)
    assert :date_time in Demo.supported_entities(:fast)
    refute :organization in Demo.supported_entities(:fast)

    for profile <- [:balanced, :accurate] do
      assert :organization in Demo.supported_entities(profile)
      refute :street_address in Demo.supported_entities(profile)
      refute :date_time in Demo.supported_entities(profile)
    end
  end

  test "groups common and advanced entities without overlap" do
    assert Demo.common_entities() ==
             [:email, :phone, :person, :location, :organization, :credit_card, :us_ssn, :domain]

    assert MapSet.disjoint?(
             MapSet.new(Demo.common_entities()),
             MapSet.new(Demo.advanced_entities())
           )

    assert MapSet.new(Demo.common_entities() ++ Demo.advanced_entities()) ==
             MapSet.new(Demo.entities())
  end

  test "describes model preparation using public profile data" do
    rows = Demo.profile_rows()
    balanced = Enum.find(rows, &(&1.name == :balanced))
    accurate = Enum.find(rows, &(&1.name == :accurate))

    assert balanced.descriptor.implementation_profile == :hybrid_ner_tner_conservative
    assert balanced.preparation.approximate_cache_size == "about 1.4 GB"

    assert [%{name: "tner/roberta-large-ontonotes5", source: source}] =
             balanced.preparation.models

    assert source == "https://huggingface.co/tner/roberta-large-ontonotes5"
    assert length(accurate.preparation.models) == 2
    assert is_binary(accurate.preparation.cache_destination)
  end

  test "rejects unsupported entities in crafted submissions", %{vault: vault} do
    params = %{text_params("detect", "replace") | "entities" => ["organization"]}

    assert {:error, "Unsupported for :fast: organization."} =
             Demo.run_text(params, %{}, vault)
  end

  test "requires a reusable runtime before model-backed inference", %{vault: vault} do
    params = %{text_params("detect", "replace") | "profile" => "balanced"}

    assert {:error, "Prepare :balanced in Profiles before running inference."} =
             Demo.run_text(params, %{}, vault)
  end

  defp text_params(action, operator) do
    %{
      "input" => "Email rachel.green@example.com or +1 202-555-0188",
      "profile" => "fast",
      "entities" => ["email", "phone"],
      "action" => action,
      "operator" => operator
    }
  end
end
