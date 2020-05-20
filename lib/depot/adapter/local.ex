defmodule Depot.Adapter.Local do
  @moduledoc """
  Depot Adapter for the local filesystem.

  ## Direct usage

      iex> {:ok, prefix} = Briefly.create(directory: true)
      iex> filesystem = Depot.Adapter.Local.configure(prefix: prefix)
      iex> :ok = Depot.write(filesystem, "test.txt", "Hello World")
      iex> {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")

  ## Usage with a module

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      LocalFileSystem.write("test.txt", "Hello World")
      {:ok, "Hello World"} = LocalFileSystem.read("test.txt")
  """

  defmodule Config do
    @moduledoc false
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
    path = full_path(config, path)

    with :ok <- path |> Path.dirname() |> File.mkdir_p() do
      File.write(path, contents)
    end
  end

  @impl Depot.Adapter
  def read(%Config{} = config, path) do
    File.read(full_path(config, path))
  end

  @impl Depot.Adapter
  def delete(%Config{} = config, path) do
    with {:error, :enoent} <- File.rm(full_path(config, path)), do: :ok
  end

  @impl Depot.Adapter
  def move(%Config{} = config, source, destination) do
    source = full_path(config, source)
    destination = full_path(config, destination)

    with :ok <- destination |> Path.dirname() |> File.mkdir_p() do
      File.rename(source, destination)
    end
  end

  @impl Depot.Adapter
  def copy(%Config{} = config, source, destination) do
    source = full_path(config, source)
    destination = full_path(config, destination)

    with :ok <- destination |> Path.dirname() |> File.mkdir_p() do
      File.cp(source, destination)
    end
  end

  @impl Depot.Adapter
  def list_contents(%Config{} = config, path) do
    path = full_path(config, path)

    with {:ok, files} <- File.ls(path) do
      contents =
        for file <- files,
            {:ok, stat} = File.stat(Path.join(path, file), time: :posix),
            stat.type in [:directory, :regular] do
          case stat.type do
            :directory -> %Depot.Stat.Dir{name: file, size: stat.size, mtime: stat.mtime}
            :regular -> %Depot.Stat.File{name: file, size: stat.size, mtime: stat.mtime}
          end
        end

      {:ok, contents}
    end
  end

  defp full_path(config, path) do
    Depot.RelativePath.join_prefix(config.prefix, path)
  end
end
