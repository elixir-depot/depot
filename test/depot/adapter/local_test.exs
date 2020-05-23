defmodule Depot.Adapter.LocalTest do
  use ExUnit.Case, async: true
  import Depot.AdapterTest
  doctest Depot.Adapter.Local

  setup do
    {:ok, prefix} = Briefly.create(directory: true)
    {:ok, prefix: prefix}
  end

  adapter_test %{prefix: prefix} do
    filesystem = Depot.Adapter.Local.configure(prefix: prefix)
    {:ok, filesystem: filesystem}
  end

  describe "write" do
    test "success", %{prefix: prefix} do
      {_, config} = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.Adapter.Local.write(config, "test.txt", "Hello World")

      assert {:ok, "Hello World"} = File.read(Path.join(prefix, "test.txt"))
    end

    test "folders are automatically created is missing", %{prefix: prefix} do
      {_, config} = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.Adapter.Local.write(config, "folder/test.txt", "Hello World")

      assert {:ok, "Hello World"} = File.read(Path.join(prefix, "folder/test.txt"))
    end
  end

  describe "read" do
    test "success", %{prefix: prefix} do
      {_, config} = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = File.write(Path.join(prefix, "test.txt"), "Hello World")

      assert {:ok, "Hello World"} = Depot.Adapter.Local.read(config, "test.txt")
    end
  end

  describe "delete" do
    test "success", %{prefix: prefix} do
      {_, config} = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = File.write(Path.join(prefix, "test.txt"), "Hello World")

      assert :ok = Depot.Adapter.Local.delete(config, "test.txt")

      assert {:error, :enoent} = File.read(Path.join(prefix, "folder/test.txt"))
    end

    test "successful even if no file to delete", %{prefix: prefix} do
      {_, config} = Depot.Adapter.Local.configure(prefix: prefix)

      assert :ok = Depot.Adapter.Local.delete(config, "test.txt")

      assert {:error, :enoent} = File.read(Path.join(prefix, "folder/test.txt"))
    end
  end
end
