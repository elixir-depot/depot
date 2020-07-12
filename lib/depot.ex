defmodule Depot do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @type adapter :: module()
  @type filesystem :: {module(), Depot.Adapter.config()}

  @doc """
  Write to a filesystem

  ## Examples

  ### Direct filesystem

      filesystem = Depot.Adapter.Local.configure(prefix: "/home/user/storage")
      :ok = Depot.write(filesystem, "test.txt", "Hello World")

  ### Module-based filesystem

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: "/home/user/storage"
      end

      LocalFileSystem.write("test.txt", "Hello World")

  """
  @spec write(filesystem, Path.t(), iodata(), keyword()) :: :ok | {:error, term}
  def write({adapter, config}, path, contents, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.write(config, path, contents)
    end
  end

  @doc """
  Read from a filesystem

  ## Examples

  ### Direct filesystem

      filesystem = Depot.Adapter.Local.configure(prefix: "/home/user/storage")
      {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")

  ### Module-based filesystem

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: "/home/user/storage"
      end

      {:ok, "Hello World"} = LocalFileSystem.read("test.txt")

  """
  @spec read(filesystem, Path.t(), keyword()) :: {:ok, binary} | {:error, term}
  def read({adapter, config}, path, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.read(config, path)
    end
  end

  @doc """
  Returns a `Stream` for reading the given `path`.

  ## Options

  The following stream options apply to all adapters:

    * `:chunk_size` - When reading, the amount to read,
      usually expressed as a number of bytes.

  ## Examples

  > Note: The shape of the returned stream will
  > necessarily depend on the adapter in use. In the
  > following examples the [`Local`](`Depot.Adapter.Local`)
  > adapter is invoked, which returns a `File.Stream`.

  ### Direct filesystem

      filesystem = Depot.Adapter.Local.configure(prefix: "/home/user/storage")
      {:ok, %File.Stream{}} = Depot.read_stream(filesystem, "test.txt")

  ### Module-based filesystem

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: "/home/user/storage"
      end

      {:ok, %File.Stream{}} = LocalFileSystem.read_stream("test.txt")

  """
  def read_stream({adapter, config}, path, opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.read_stream(config, path, opts)
    end
  end

  @doc """
  Delete a file from a filesystem

  ## Examples

  ### Direct filesystem

      filesystem = Depot.Adapter.Local.configure(prefix: "/home/user/storage")
      :ok = Depot.delete(filesystem, "test.txt")

  ### Module-based filesystem

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: "/home/user/storage"
      end

      :ok = LocalFileSystem.delete("test.txt")

  """
  @spec delete(filesystem, Path.t(), keyword()) :: :ok | {:error, term}
  def delete({adapter, config}, path, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.delete(config, path)
    end
  end

  @doc """
  Move a file from source to destination on a filesystem

  ## Examples

  ### Direct filesystem

      filesystem = Depot.Adapter.Local.configure(prefix: "/home/user/storage")
      :ok = Depot.move(filesystem, "test.txt", "other-test.txt")

  ### Module-based filesystem

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: "/home/user/storage"
      end

      :ok = LocalFileSystem.move("test.txt", "other-test.txt")

  """
  @spec move(filesystem, Path.t(), Path.t(), keyword()) :: :ok | {:error, term}
  def move({adapter, config}, source, destination, _opts \\ []) do
    with {:ok, source} <- Depot.RelativePath.normalize(source),
         {:ok, destination} <- Depot.RelativePath.normalize(destination) do
      adapter.move(config, source, destination)
    end
  end

  @doc """
  Copy a file from source to destination on a filesystem

  ## Examples

  ### Direct filesystem

      filesystem = Depot.Adapter.Local.configure(prefix: "/home/user/storage")
      :ok = Depot.copy(filesystem, "test.txt", "other-test.txt")

  ### Module-based filesystem

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: "/home/user/storage"
      end

      :ok = LocalFileSystem.copy("test.txt", "other-test.txt")

  """
  @spec copy(filesystem, Path.t(), Path.t(), keyword()) :: :ok | {:error, term}
  def copy({adapter, config}, source, destination, _opts \\ []) do
    with {:ok, source} <- Depot.RelativePath.normalize(source),
         {:ok, destination} <- Depot.RelativePath.normalize(destination) do
      adapter.copy(config, source, destination)
    end
  end

  @doc """
  Copy a file from source to destination on a filesystem

  ## Examples

  ### Direct filesystem

      filesystem = Depot.Adapter.Local.configure(prefix: "/home/user/storage")
      :ok = Depot.copy(filesystem, "test.txt", "other-test.txt")

  ### Module-based filesystem

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: "/home/user/storage"
      end

      :ok = LocalFileSystem.copy("test.txt", "other-test.txt")

  """
  @spec file_exists(filesystem, Path.t(), keyword()) :: {:ok, :exists | :missing} | {:error, term}
  def file_exists({adapter, config}, path, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.file_exists(config, path)
    end
  end

  @doc """
  List the contents of a folder on a filesystem

  ## Examples

  ### Direct filesystem

      filesystem = Depot.Adapter.Local.configure(prefix: "/home/user/storage")
      {:ok, contents} = Depot.list_contents(filesystem, ".")

  ### Module-based filesystem

      defmodule LocalFileSystem do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: "/home/user/storage"
      end

      {:ok, contents} = LocalFileSystem.list_contents(".")

  """
  @spec list_contents(filesystem, Path.t(), keyword()) ::
          {:ok, [%Depot.Stat.Dir{} | %Depot.Stat.File{}]} | {:error, term}
  def list_contents({adapter, config}, path, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.list_contents(config, path)
    end
  end
end
