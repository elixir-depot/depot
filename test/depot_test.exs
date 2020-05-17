defmodule DepotTest do
  use ExUnit.Case

  test "user can write to filesystem without intermediate processes" do
    {:ok, prefix} = Briefly.create(directory: true)
    filesystem = Depot.Adapter.Local.configure(prefix: prefix)

    :ok = Depot.write(filesystem, "test.txt", "Hello World")

    assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
  end

  test "user can write to filesystem with intermediate processes" do
    filesystem = Depot.Adapter.InMemory.configure(name: InMemoryTest)

    start_supervised(filesystem)

    :ok = Depot.write(filesystem, "test.txt", "Hello World")

    assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
  end

  test "user can write to filesystem of module" do
    {:ok, prefix} = Briefly.create(directory: true)

    defmodule LocalTest do
      use Depot,
        adapter: Depot.Adapter.Local,
        prefix: prefix
    end

    :ok = LocalTest.write("test.txt", "Hello World")

    assert {:ok, "Hello World"} = LocalTest.read("test.txt")
  end

  test "user can write to filesystem of module 2" do
    defmodule InMemoryTest do
      use Depot,
        adapter: Depot.Adapter.InMemory
    end

    start_supervised(InMemoryTest)

    :ok = InMemoryTest.write("test.txt", "Hello World")

    assert {:ok, "Hello World"} = InMemoryTest.read("test.txt")
  end

  test "directory traversals are detected and reported" do
    {:ok, prefix} = Briefly.create(directory: true)
    filesystem = Depot.Adapter.Local.configure(prefix: prefix)

    {:error, {:path, :traversal}} = Depot.write(filesystem, "../test.txt", "Hello World")
    {:error, {:path, :traversal}} = Depot.read(filesystem, "../test.txt")
    {:error, {:path, :traversal}} = Depot.delete(filesystem, "../test.txt")
    {:error, {:path, :traversal}} = Depot.list_contents(filesystem, "../test")
  end

  test "relative paths are required" do
    {:ok, prefix} = Briefly.create(directory: true)
    filesystem = Depot.Adapter.Local.configure(prefix: prefix)

    {:error, {:path, :absolute}} = Depot.write(filesystem, "/../test.txt", "Hello World")
    {:error, {:path, :absolute}} = Depot.read(filesystem, "/../test.txt")
    {:error, {:path, :absolute}} = Depot.delete(filesystem, "/../test.txt")
    {:error, {:path, :absolute}} = Depot.list_contents(filesystem, "/../test")
  end
end
