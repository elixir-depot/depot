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
    end
  end

  @callback write(path :: Path.t(), contents :: binary, opts :: keyword()) :: :ok | {:error, term}
  @callback read(path :: Path.t(), opts :: keyword()) :: {:ok, binary} | {:error, term}

  @doc false
  def write({adapter, config}, path, contents, _opts \\ []) do
    adapter.write(config, path, contents)
  end

  @doc false
  def read({adapter, config}, path, _opts \\ []) do
    adapter.read(config, path)
  end
end
