defmodule Depot.Adapter do
  @moduledoc """
  Behaviour for how `Depot` adapters work.
  """
  @type path :: Path.t()
  @opaque config :: struct

  @callback starts_processes() :: boolean
  @callback configure(keyword) :: {module(), config}
  @callback write(config, path, contents :: iodata()) :: :ok | {:error, term}
  @callback read(config, path) :: {:ok, binary} | {:error, term}
  @callback delete(config, path) :: :ok | {:error, term}
  @callback list_contents(config, path) ::
              {:ok, [%Depot.Stat.Dir{} | %Depot.Stat.File{}]} | {:error, term}
end
