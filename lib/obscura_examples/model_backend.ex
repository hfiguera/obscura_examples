defmodule ObscuraExamples.ModelBackend do
  @moduledoc false

  @type backend :: :binary | :emily | :exla

  @spec options((module() -> boolean())) :: [{String.t(), String.t()}]
  def options(dependency_checker \\ &Code.ensure_loaded?/1) do
    []
    |> maybe_add_backend(
      dependencies_loaded?([Emily, Emily.Backend], dependency_checker),
      {"Emily GPU", "emily"}
    )
    |> maybe_add_backend(
      dependencies_loaded?([EXLA, EXLA.Backend], dependency_checker),
      {"EXLA CUDA", "exla"}
    )
    |> Kernel.++([{"Binary CPU", "binary"}])
  end

  @spec parse(String.t()) :: {:ok, backend()} | {:error, String.t()}
  def parse("emily"), do: {:ok, :emily}
  def parse("exla"), do: {:ok, :exla}
  def parse("binary"), do: {:ok, :binary}
  def parse(_backend), do: {:error, "Unknown backend."}

  @spec preparation_options(backend()) :: keyword()
  def preparation_options(:emily) do
    [real_model_backend: :emily, emily_device: :gpu, emily_fallback: :raise]
  end

  def preparation_options(backend) when backend in [:binary, :exla] do
    [real_model_backend: backend]
  end

  defp dependencies_loaded?(modules, dependency_checker) do
    Enum.all?(modules, dependency_checker)
  end

  defp maybe_add_backend(backends, true, backend), do: backends ++ [backend]
  defp maybe_add_backend(backends, false, _backend), do: backends
end
