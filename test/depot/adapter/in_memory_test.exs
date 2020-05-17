defmodule Depot.Adapter.InMemoryTest do
  use ExUnit.Case, async: true
  doctest Depot.Adapter.InMemory

  describe "write" do
    test "success", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok = Depot.Adapter.InMemory.write(config, "test.txt", "Hello World")

      assert {:ok, "Hello World"} =
               Agent.get(via(test), fn state -> Map.fetch(state, "test.txt") end)
    end

    test "folders are automatically created is missing", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok = Depot.Adapter.InMemory.write(config, "folder/test.txt", "Hello World")

      assert {:ok, "Hello World"} = Depot.Adapter.InMemory.read(config, "folder/test.txt")
    end
  end

  describe "read" do
    test "success", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok = Agent.update(via(test), fn state -> Map.put(state, "test.txt", "Hello World") end)

      assert {:ok, "Hello World"} = Depot.Adapter.InMemory.read(config, "test.txt")
    end
  end

  describe "delete" do
    test "success", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok = Agent.update(via(test), fn state -> Map.put(state, "test.txt", "Hello World") end)

      assert :ok = Depot.Adapter.InMemory.delete(config, "test.txt")

      assert :error = Agent.get(via(test), fn state -> Map.fetch(state, "test.txt") end)
    end

    test "successful even if no file to delete", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      assert :ok = Depot.Adapter.InMemory.delete(config, "test.txt")

      assert :error = Agent.get(via(test), fn state -> Map.fetch(state, "test.txt") end)
    end
  end

  defp via(name) do
    Depot.Registry.via(Depot.Adapter.InMemory, name)
  end
end
