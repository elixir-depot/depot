defmodule Depot do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @type adapter :: module()
  @type filesystem :: {module(), Depot.Adapter.config()}

  @doc """
  Bundle a filesystem in a module.
  """
  defmacro __using__(opts) do
    {adapter, opts} = Keyword.pop!(opts, :adapter)

    quote do
      opts = unquote(opts)
      opts = Keyword.put_new(opts, :name, __MODULE__)

      @behaviour unquote(__MODULE__)
      @adapter unquote(adapter)
      @filesystem @adapter.configure(opts)

      if @adapter.starts_processes() do
        def child_spec(_) do
          Supervisor.child_spec(@filesystem, %{})
        end
      end

      def __filesystem__ do
        @filesystem
      end

      @impl true
      def write(path, contents, opts \\ []),
        do: Depot.write(@filesystem, path, contents, opts)

      @impl true
      def read(path, opts \\ []),
        do: Depot.read(@filesystem, path, opts)

      @impl true
      def delete(path, opts \\ []),
        do: Depot.delete(@filesystem, path, opts)

      @impl true
      def move(source, destination, opts \\ []),
        do: Depot.move(@filesystem, source, destination, opts)

      @impl true
      def copy(source, destination, opts \\ []),
        do: Depot.copy(@filesystem, source, destination, opts)

      @impl true
      def list_contents(path, opts \\ []),
        do: Depot.list_contents(@filesystem, path, opts)
    end
  end

  @callback write(path :: Path.t(), contents :: binary, opts :: keyword()) :: :ok | {:error, term}
  @callback read(path :: Path.t(), opts :: keyword()) :: {:ok, binary} | {:error, term}
  @callback delete(path :: Path.t(), opts :: keyword()) :: :ok | {:error, term}
  @callback move(source :: Path.t(), destination :: Path.t(), opts :: keyword()) ::
              :ok | {:error, term}
  @callback copy(source :: Path.t(), destination :: Path.t(), opts :: keyword()) ::
              :ok | {:error, term}
  @callback list_contents(path :: Path.t(), opts :: keyword()) ::
              {:ok, [%Depot.Stat.Dir{} | %Depot.Stat.File{}]} | {:error, term}

  @spec write({any, any}, binary, any, any) :: any
  def write({adapter, config}, path, contents, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.write(config, path, contents)
    end
  end

  def read({adapter, config}, path, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.read(config, path)
    end
  end

  def delete({adapter, config}, path, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.delete(config, path)
    end
  end

  def move({adapter, config}, source, destination, _opts \\ []) do
    with {:ok, source} <- Depot.RelativePath.normalize(source),
         {:ok, destination} <- Depot.RelativePath.normalize(destination) do
      adapter.move(config, source, destination)
    end
  end

  def copy({adapter, config}, source, destination, _opts \\ []) do
    with {:ok, source} <- Depot.RelativePath.normalize(source),
         {:ok, destination} <- Depot.RelativePath.normalize(destination) do
      adapter.copy(config, source, destination)
    end
  end

  def list_contents({adapter, config}, path, _opts \\ []) do
    with {:ok, path} <- Depot.RelativePath.normalize(path) do
      adapter.list_contents(config, path)
    end
  end
end
