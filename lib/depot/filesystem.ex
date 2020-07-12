defmodule Depot.Filesystem do
  @moduledoc """
  Behaviour of a `Depot` filesystem.
  """
  @callback write(path :: Path.t(), contents :: binary, opts :: keyword()) :: :ok | {:error, term}
  @callback read(path :: Path.t(), opts :: keyword()) :: {:ok, binary} | {:error, term}
  @callback read_stream(path :: Path.t(), opts :: keyword()) ::
              {:ok, Enumerable.t()} | {:error, term}
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
    quote bind_quoted: [opts: opts] do
      @behaviour Depot.Filesystem

      {adapter, opts} = Depot.Filesystem.parse_opts(__MODULE__, opts)
      opts = Keyword.put_new(opts, :name, __MODULE__)
      @filesystem adapter.configure(opts)

      if adapter.starts_processes() do
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
      def read_stream(path, opts \\ []),
        do: Depot.read_stream(@filesystem, path, opts)

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

  def parse_opts(module, opts) do
    if Keyword.has_key?(opts, :otp_app) do
      otp_app = Keyword.fetch!(opts, :otp_app)
      config = Application.get_env(otp_app, module, [])
      adapter = opts[:adapter] || config[:adapter]

      unless adapter do
        raise ArgumentError, "missing :adapter configuration in " <>
                             "config #{inspect otp_app}, #{inspect module}"
      end

      {adapter, config}
    else
      {adapter, config} = Keyword.pop!(opts, :adapter)
    end
  end
end
