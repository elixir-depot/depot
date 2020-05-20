defmodule DepotTest do
  use ExUnit.Case, async: true

  defmacrop assert_in_list(list, match) do
    quote do
      assert Enum.any?(unquote(list), &match?(unquote(match), &1))
    end
  end

  describe "filesystem without own processes" do
    setup do
      {:ok, prefix} = Briefly.create(directory: true)
      {:ok, prefix: prefix}
    end

    test "user can write to filesystem", %{prefix: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      assert :ok = Depot.write(filesystem, "test.txt", "Hello World")
    end

    test "user can read from filesystem", %{prefix: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")

      assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
    end

    test "user can delete from filesystem", %{prefix: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.delete(filesystem, "test.txt")

      assert {:error, _} = Depot.read(filesystem, "test.txt")
    end

    test "user can list files", %{prefix: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.write(filesystem, "test-1.txt", "Hello World")

      {:ok, list} = Depot.list_contents(filesystem, ".")

      assert length(list) == 2
      assert_in_list list, %Depot.Stat.File{name: "test.txt"}
      assert_in_list list, %Depot.Stat.File{name: "test-1.txt"}
    end
  end

  describe "module based filesystem without own processes" do
    setup do
      {:ok, prefix} = Briefly.create(directory: true)
      {:ok, prefix: prefix}
    end

    test "user can write to filesystem", %{prefix: prefix} do
      defmodule Local.WriteTest do
        use Depot,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      assert :ok = Local.WriteTest.write("test.txt", "Hello World")
    end

    test "user can read from filesystem", %{prefix: prefix} do
      defmodule Local.ReadTest do
        use Depot,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.ReadTest.write("test.txt", "Hello World")

      assert {:ok, "Hello World"} = Local.ReadTest.read("test.txt")
    end

    test "user can delete from filesystem", %{prefix: prefix} do
      defmodule Local.DeleteTest do
        use Depot,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.DeleteTest.write("test.txt", "Hello World")
      :ok = Local.DeleteTest.delete("test.txt")

      assert {:error, _} = Local.DeleteTest.read("test.txt")
    end

    test "user can list files", %{prefix: prefix} do
      defmodule Local.ListContentsTest do
        use Depot,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.ListContentsTest.write("test.txt", "Hello World")
      :ok = Local.ListContentsTest.write("test-1.txt", "Hello World")

      {:ok, list} = Local.ListContentsTest.list_contents(".")

      assert length(list) == 2
      assert_in_list list, %Depot.Stat.File{name: "test.txt"}
      assert_in_list list, %Depot.Stat.File{name: "test-1.txt"}
    end
  end

  describe "filesystem with own processes" do
    test "user can write to filesystem" do
      filesystem = Depot.Adapter.InMemory.configure(name: InMemoryTest)

      start_supervised(filesystem)

      assert :ok = Depot.write(filesystem, "test.txt", "Hello World")
    end

    test "user can read from filesystem" do
      filesystem = Depot.Adapter.InMemory.configure(name: InMemoryTest)

      start_supervised(filesystem)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")

      assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
    end

    test "user can delete from filesystem" do
      filesystem = Depot.Adapter.InMemory.configure(name: InMemoryTest)

      start_supervised(filesystem)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.delete(filesystem, "test.txt")

      assert {:error, _} = Depot.read(filesystem, "test.txt")
    end

    test "user can list files" do
      filesystem = Depot.Adapter.InMemory.configure(name: InMemoryTest)

      start_supervised(filesystem)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.write(filesystem, "test-1.txt", "Hello World")

      {:ok, list} = Depot.list_contents(filesystem, ".")

      assert length(list) == 2
      assert_in_list list, %Depot.Stat.File{name: "test.txt"}
      assert_in_list list, %Depot.Stat.File{name: "test-1.txt"}
    end
  end

  describe "module based filesystem with own processes" do
    test "user can write to filesystem" do
      defmodule InMemory.WriteTest do
        use Depot,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.WriteTest)

      assert :ok = InMemory.WriteTest.write("test.txt", "Hello World")
    end

    test "user can read from filesystem" do
      defmodule InMemory.ReadTest do
        use Depot,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.ReadTest)

      :ok = InMemory.ReadTest.write("test.txt", "Hello World")

      assert {:ok, "Hello World"} = InMemory.ReadTest.read("test.txt")
    end

    test "user can delete from filesystem" do
      defmodule InMemory.DeleteTest do
        use Depot,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.DeleteTest)

      :ok = InMemory.DeleteTest.write("test.txt", "Hello World")
      :ok = InMemory.DeleteTest.delete("test.txt")

      assert {:error, _} = InMemory.DeleteTest.read("test.txt")
    end

    test "user can list files" do
      defmodule InMemory.ListContentsTest do
        use Depot,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.ListContentsTest)

      :ok = InMemory.ListContentsTest.write("test.txt", "Hello World")
      :ok = InMemory.ListContentsTest.write("test-1.txt", "Hello World")

      {:ok, list} = InMemory.ListContentsTest.list_contents(".")

      assert length(list) == 2
      assert_in_list list, %Depot.Stat.File{name: "test.txt"}
      assert_in_list list, %Depot.Stat.File{name: "test-1.txt"}
    end
  end

  describe "filesystem independant" do
    setup do
      {:ok, prefix} = Briefly.create(directory: true)
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)
      {:ok, filesystem: filesystem}
    end

    test "directory traversals are detected and reported", %{filesystem: filesystem} do
      {:error, {:path, :traversal}} = Depot.write(filesystem, "../test.txt", "Hello World")
      {:error, {:path, :traversal}} = Depot.read(filesystem, "../test.txt")
      {:error, {:path, :traversal}} = Depot.delete(filesystem, "../test.txt")
      {:error, {:path, :traversal}} = Depot.list_contents(filesystem, "../test")
    end

    test "relative paths are required", %{filesystem: filesystem} do
      {:error, {:path, :absolute}} = Depot.write(filesystem, "/../test.txt", "Hello World")
      {:error, {:path, :absolute}} = Depot.read(filesystem, "/../test.txt")
      {:error, {:path, :absolute}} = Depot.delete(filesystem, "/../test.txt")
      {:error, {:path, :absolute}} = Depot.list_contents(filesystem, "/../test")
    end
  end
end
