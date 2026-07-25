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

  test "Obscura is fetched from the published Hex release" do
    lock = Mix.Dep.Lock.read()[:obscura]

    assert {:hex, :obscura, "0.1.2", package_checksum, [:mix], _dependencies, "hexpm",
            release_checksum} = lock

    assert byte_size(package_checksum) == 64

    assert release_checksum ==
             "7e0ef15726a14fe1f7decd413db5e6e456e3921e70b5bfa509c2e0d31a1284f8"
  end
end
