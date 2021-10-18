defmodule Depot.Adapter.InMemoryTest do
  use ExUnit.Case, async: true
  import Depot.AdapterTest
  import Depot.ListAssertions
  doctest Depot.Adapter.InMemory

  adapter_test %{test: test} do
    filesystem = Depot.Adapter.InMemory.configure(name: test)
    start_supervised(filesystem)
    {:ok, filesystem: filesystem}
  end

  describe "write" do
    test "success", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok = Depot.Adapter.InMemory.write(config, "test.txt", "Hello World", [])

      assert {:ok, {"Hello World", _meta}} =
               Agent.get(via(test), fn state ->
                 state
                 |> elem(0)
                 |> Map.fetch!("/")
                 |> elem(0)
                 |> Map.fetch("test.txt")
               end)
    end

    test "folders are automatically created is missing", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok = Depot.Adapter.InMemory.write(config, "folder/test.txt", "Hello World", [])

      assert {:ok, "Hello World"} = Depot.Adapter.InMemory.read(config, "folder/test.txt")
    end
  end

  describe "read" do
    test "success", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok =
        Agent.update(via(test), fn _state ->
          {%{"/" => {%{"test.txt" => {"Hello World", %{}}}, %{}}}, %{}}
        end)

      assert {:ok, "Hello World"} = Depot.Adapter.InMemory.read(config, "test.txt")
    end

    test "stream success", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok =
        Agent.update(via(test), fn _state ->
          {%{"/" => {%{"test.txt" => {"Hello World", %{}}}, %{}}}, %{}}
        end)

      assert {:ok, %Depot.Adapter.InMemory.AgentStream{} = stream} =
               Depot.Adapter.InMemory.read_stream(config, "test.txt", [])

      assert Enum.into(stream, <<>>) == "Hello World"
    end
  end

  describe "listing contents" do
    test "lists files and folders", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok = Depot.Adapter.InMemory.write(config, "test.txt", "Hello World", [])
      :ok = Depot.Adapter.InMemory.write(config, "folder/test.txt", "Hello World", [])

      {:ok, contents} = Depot.Adapter.InMemory.list_contents(config, "/")

      assert length(contents) == 2
      assert_in_list contents, %Depot.Stat.File{name: "test.txt", path: ""}
      assert_in_list contents, %Depot.Stat.Dir{name: "folder"}
    end

    test "lists files include a path relative to the filesystem", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok =
        Depot.Adapter.InMemory.write(config, "deeply/nested/folder/test.txt", "Hello World", [])

      {:ok, contents} = Depot.Adapter.InMemory.list_contents(config, "/deeply/nested/folder")

      assert length(contents) == 1
      assert_in_list contents, %Depot.Stat.File{name: "test.txt", path: "deeply/nested/folder"}
    end
  end

  describe "delete" do
    test "success", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      :ok =
        Agent.update(via(test), fn _state ->
          {%{"/" => {%{"test.txt" => {"Hello World", %{}}}, %{}}}, %{}}
        end)

      assert :ok = Depot.Adapter.InMemory.delete(config, "test.txt")

      assert :error =
               Agent.get(via(test), fn state ->
                 state
                 |> elem(0)
                 |> Map.fetch!("/")
                 |> elem(0)
                 |> Map.fetch("test.txt")
               end)
    end

    test "successful even if no file to delete", %{test: test} do
      {_, config} = filesystem = Depot.Adapter.InMemory.configure(name: test)

      start_supervised(filesystem)

      assert :ok = Depot.Adapter.InMemory.delete(config, "test.txt")
    end
  end

  defp via(name) do
    Depot.Registry.via(Depot.Adapter.InMemory, name)
  end
end
