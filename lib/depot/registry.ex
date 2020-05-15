defmodule Depot.Registry do
  def child_spec(_) do
    Registry.child_spec(keys: :unique, name: __MODULE__)
  end

  def via(adapter, name) do
    {:via, Registry, {__MODULE__, {adapter, name}}}
  end
end
