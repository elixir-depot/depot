defmodule Depot.Adapter do
  @moduledoc """
  Behaviour for how `Depot` adapters work.
  """
  @type path :: Path.t()
  @type stream_opts :: keyword
  @type config :: struct

  @callback starts_processes() :: boolean
  @callback configure(keyword) :: {module(), config}
  @callback write(config, path, contents :: iodata()) :: :ok | {:error, term}
  @callback read(config, path) :: {:ok, binary} | {:error, term}
  @callback read_stream(config, path, stream_opts) :: {:ok, Enumerable.t()} | {:error, term}
  @callback delete(config, path) :: :ok | {:error, term}
  @callback move(config, source :: path, destination :: path) :: :ok | {:error, term}
  @callback copy(config, source :: path, destination :: path) :: :ok | {:error, term}
  @callback file_exists(config, path) :: {:ok, :exists | :missing} | {:error, term}
  @callback list_contents(config, path) ::
              {:ok, [%Depot.Stat.Dir{} | %Depot.Stat.File{}]} | {:error, term}
end
