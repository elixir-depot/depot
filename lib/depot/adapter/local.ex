defmodule Depot.Adapter.Local do
  defmodule Config do
    defstruct prefix: nil
  end

  @behaviour Depot.Adapter

  @impl Depot.Adapter
  def starts_processes, do: false

  @impl Depot.Adapter
  def configure(opts) do
    config = %Config{
      prefix: Keyword.fetch!(opts, :prefix)
    }

    {__MODULE__, config}
  end

  @impl Depot.Adapter
  def write(%Config{} = config, path, contents) do
    path = Path.join(config.prefix, path)

    with :ok <- path |> Path.dirname() |> File.mkdir_p() do
      File.write(path, contents)
    end
  end

  @impl Depot.Adapter
  def read(%Config{} = config, path) do
    path = Path.join(config.prefix, path)
    File.read(path)
  end

  @impl Depot.Adapter
  def delete(%Config{} = config, path) do
    path = Path.join(config.prefix, path)
    with {:error, :enoent} <- File.rm(path), do: :ok
  end
end
