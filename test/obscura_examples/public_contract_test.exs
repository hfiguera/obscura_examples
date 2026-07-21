defmodule ObscuraExamples.PublicContractTest do
  use ExUnit.Case, async: true

  @consumed_modules [
    Obscura,
    Obscura.Diagnostic,
    Obscura.LLM,
    Obscura.Logger,
    Obscura.Phoenix.Plug,
    Obscura.Profile,
    Obscura.Stream.Rehydrator,
    Obscura.Structured,
    Obscura.Vault,
    Obscura.Vault.Memory
  ]

  test "every consumed Obscura module belongs to the stable API manifest" do
    manifest_path = Application.app_dir(:obscura, "priv/obscura/public_api.exs")
    {manifest, _binding} = Code.eval_file(manifest_path)

    for module <- @consumed_modules do
      assert Map.has_key?(manifest.stable, module),
             "#{inspect(module)} is not declared stable by Obscura"
    end
  end

  test "Obscura is fetched as a git dependency from canonical main" do
    lock = Mix.Dep.Lock.read()[:obscura]

    assert {:git, "git@github.com:hfiguera/obscura.git", revision, [branch: "main"]} = lock
    assert is_binary(revision)
    assert byte_size(revision) == 40
  end
end
