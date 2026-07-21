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

  test "exposes only the stable product profile set" do
    assert Demo.profiles() == Obscura.Profile.names()
    assert Demo.profiles() == [:fast, :balanced, :accurate]
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
