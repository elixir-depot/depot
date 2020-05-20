defmodule Depot.Adapter.InMemory do
  @moduledoc """
  Depot Adapter using an `Agent` for in memory storage.

  ## Direct usage

      iex> filesystem = Depot.Adapter.InMemory.configure(name: InMemoryFileSystem)
      iex> start_supervised(filesystem)
      iex> :ok = Depot.write(filesystem, "test.txt", "Hello World")
      iex> {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")

  ## Usage with a module

      defmodule InMemoryFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemoryFileSystem)

      InMemoryFileSystem.write("test.txt", "Hello World")
      {:ok, "Hello World"} = InMemoryFileSystem.read("test.txt")
  """

  use Agent

  defmodule Config do
    @moduledoc false
    defstruct name: nil
  end

  @behaviour Depot.Adapter

  @impl Depot.Adapter
  def starts_processes, do: true

  def start_link({__MODULE__, %Config{} = config}) do
    start_link(config)
  end

  def start_link(%Config{} = config) do
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
      put_in(state, accessor(path, %{}), IO.iodata_to_binary(contents))
    end)
  end

  @impl Depot.Adapter
  def read(config, path) do
    Agent.get(Depot.Registry.via(__MODULE__, config.name), fn state ->
      case get_in(state, accessor(path)) do
        binary when is_binary(binary) -> {:ok, binary}
        _ -> {:error, :enoent}
      end
    end)
  end

  @impl Depot.Adapter
  def delete(%Config{} = config, path) do
    Agent.update(Depot.Registry.via(__MODULE__, config.name), fn state ->
      {_, state} = pop_in(state, accessor(path))
      state
    end)

    :ok
  end

  @impl Depot.Adapter
  def move(%Config{} = config, source, destination) do
    Agent.get_and_update(Depot.Registry.via(__MODULE__, config.name), fn state ->
      case get_in(state, accessor(source)) do
        binary when is_binary(binary) ->
          {_, state} =
            state |> put_in(accessor(destination, %{}), binary) |> pop_in(accessor(source))

          {:ok, state}

        _ ->
          {{:error, :enoent}, state}
      end
    end)
  end

  @impl Depot.Adapter
  def copy(%Config{} = config, source, destination) do
    Agent.get_and_update(Depot.Registry.via(__MODULE__, config.name), fn state ->
      case get_in(state, accessor(source)) do
        binary when is_binary(binary) -> {:ok, put_in(state, accessor(destination, %{}), binary)}
        _ -> {{:error, :enoent}, state}
      end
    end)
  end

  @impl Depot.Adapter
  def file_exists(%Config{} = config, path) do
    Agent.get(Depot.Registry.via(__MODULE__, config.name), fn state ->
      case get_in(state, accessor(path)) do
        binary when is_binary(binary) -> {:ok, :exists}
        _ -> {:ok, :missing}
      end
    end)
  end

  @impl Depot.Adapter
  def list_contents(%Config{} = config, path) do
    contents =
      Agent.get(Depot.Registry.via(__MODULE__, config.name), fn state ->
        paths =
          case get_in(state, accessor(path)) do
            %{} = map -> map
            _ -> %{}
          end

        for {path, x} <- paths do
          case x do
            %{} ->
              %Depot.Stat.Dir{
                name: path,
                size: 0,
                mtime: 0
              }

            bin when is_binary(bin) ->
              %Depot.Stat.File{
                name: path,
                size: byte_size(bin),
                mtime: 0
              }
          end
        end
      end)

    {:ok, contents}
  end

  defp accessor(path, default \\ nil) when is_binary(path) do
    path
    |> Path.absname("/")
    |> Path.split()
    |> do_accessor([], default)
    |> Enum.reverse()
  end

  defp do_accessor([segment], acc, default) do
    [Access.key(segment, default) | acc]
  end

  defp do_accessor([segment | rest], acc, default) do
    do_accessor(rest, [Access.key(segment, %{}) | acc], default)
  end
end
