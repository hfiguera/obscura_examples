defmodule ObscuraExamples.ModelBackendTest do
  use ExUnit.Case, async: true

  alias ObscuraExamples.ModelBackend

  test "lists only the portable backend when accelerators are unavailable" do
    refute_loaded = fn _module -> false end

    assert ModelBackend.options(refute_loaded) == [{"Binary CPU", "binary"}]
  end

  test "lists accelerator backends only when their dependencies are loaded" do
    loaded = fn module -> module in [Emily, Emily.Backend, EXLA, EXLA.Backend] end

    assert ModelBackend.options(loaded) == [
             {"Emily GPU", "emily"},
             {"EXLA CUDA", "exla"},
             {"Binary CPU", "binary"}
           ]
  end

  test "parses all supported backend values" do
    assert ModelBackend.parse("emily") == {:ok, :emily}
    assert ModelBackend.parse("exla") == {:ok, :exla}
    assert ModelBackend.parse("binary") == {:ok, :binary}
    assert ModelBackend.parse("unknown") == {:error, "Unknown backend."}
  end

  test "keeps accelerator-specific options isolated" do
    assert ModelBackend.preparation_options(:emily) == [
             real_model_backend: :emily,
             emily_device: :gpu,
             emily_fallback: :raise
           ]

    assert ModelBackend.preparation_options(:exla) == [real_model_backend: :exla]
    assert ModelBackend.preparation_options(:binary) == [real_model_backend: :binary]
  end
end
