defmodule Depot.Adapter do
  @type path :: Path.t()
  @opaque config :: struct

  @callback starts_processes() :: boolean
  @callback configure(keyword) :: {module(), config}
  @callback write(config, path, contents :: binary) :: :ok | {:error, term}
  @callback read(config, path) :: {:ok, binary} | {:error, term}
  @callback delete(config, path) :: :ok | {:error, term}
end
