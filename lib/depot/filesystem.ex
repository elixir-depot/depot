defmodule Depot.Filesystem do
  @moduledoc """
  Behaviour of a `Depot` filesystem.
  """
  @callback write(path :: Path.t(), contents :: binary, opts :: keyword()) :: :ok | {:error, term}
  @callback read(path :: Path.t(), opts :: keyword()) :: {:ok, binary} | {:error, term}
  @callback delete(path :: Path.t(), opts :: keyword()) :: :ok | {:error, term}
  @callback move(source :: Path.t(), destination :: Path.t(), opts :: keyword()) ::
              :ok | {:error, term}
  @callback copy(source :: Path.t(), destination :: Path.t(), opts :: keyword()) ::
              :ok | {:error, term}
  @callback file_exists(path :: Path.t(), opts :: keyword()) ::
              {:ok, :exists | :missing} | {:error, term}
  @callback list_contents(path :: Path.t(), opts :: keyword()) ::
              {:ok, [%Depot.Stat.Dir{} | %Depot.Stat.File{}]} | {:error, term}

  @doc false
  @spec __using__(Macro.t()) :: Macro.t()
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
      def file_exists(path, opts \\ []),
        do: Depot.file_exists(@filesystem, path, opts)

      @impl true
      def list_contents(path, opts \\ []),
        do: Depot.list_contents(@filesystem, path, opts)
    end
  end
end
