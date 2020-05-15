defmodule Depot.Adapter.InMemory do
  use Agent

  defmodule Config do
    defstruct name: nil
  end

  @behaviour Depot.Adapter

  @impl Depot.Adapter
  def starts_processes, do: true

  def start_link(config) do
    Agent.start_link(fn -> %{} end, name: Depot.Registry.via(__MODULE__, config.name))
  end

  @impl Depot.Adapter
  def configure(opts) do
    config = %Config{
      name: Keyword.fetch!(opts, :name)
    }

    {__MODULE__, config}
  end

  @impl Depot.Adapter
  def write(config, path, contents) do
    Agent.update(Depot.Registry.via(__MODULE__, config.name), fn state ->
      Map.put(state, path, contents)
    end)
  end

  @impl Depot.Adapter
  def read(config, path) do
    Agent.get(Depot.Registry.via(__MODULE__, config.name), fn state ->
      Map.fetch(state, path)
    end)
  end

  @impl Depot.Adapter
  def delete(%Config{} = config, path) do
    Agent.update(Depot.Registry.via(__MODULE__, config.name), fn state ->
      Map.delete(state, path)
    end)

    :ok
  end
end
