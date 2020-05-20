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

    test "user can move files", %{prefix: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.move(filesystem, "test.txt", "not-test.txt")

      assert {:error, _} = Depot.read(filesystem, "test.txt")
      assert {:ok, "Hello World"} = Depot.read(filesystem, "not-test.txt")
    end

    test "user can copy files", %{prefix: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.copy(filesystem, "test.txt", "not-test.txt")

      assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
      assert {:ok, "Hello World"} = Depot.read(filesystem, "not-test.txt")
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
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      assert :ok = Local.WriteTest.write("test.txt", "Hello World")
    end

    test "user can read from filesystem", %{prefix: prefix} do
      defmodule Local.ReadTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.ReadTest.write("test.txt", "Hello World")

      assert {:ok, "Hello World"} = Local.ReadTest.read("test.txt")
    end

    test "user can delete from filesystem", %{prefix: prefix} do
      defmodule Local.DeleteTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.DeleteTest.write("test.txt", "Hello World")
      :ok = Local.DeleteTest.delete("test.txt")

      assert {:error, _} = Local.DeleteTest.read("test.txt")
    end

    test "user can move files", %{prefix: prefix} do
      defmodule Local.MoveTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.MoveTest.write("test.txt", "Hello World")
      :ok = Local.MoveTest.move("test.txt", "not-test.txt")

      assert {:error, _} = Local.MoveTest.read("test.txt")
      assert {:ok, "Hello World"} = Local.MoveTest.read("not-test.txt")
    end

    test "user can copy files", %{prefix: prefix} do
      defmodule Local.CopyTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.CopyTest.write("test.txt", "Hello World")
      :ok = Local.CopyTest.copy("test.txt", "not-test.txt")

      assert {:ok, "Hello World"} = Local.CopyTest.read("test.txt")
      assert {:ok, "Hello World"} = Local.CopyTest.read("not-test.txt")
    end

    test "user can list files", %{prefix: prefix} do
      defmodule Local.ListContentsTest do
        use Depot.Filesystem,
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

    test "user can move files" do
      filesystem = Depot.Adapter.InMemory.configure(name: InMemoryTest)

      start_supervised(filesystem)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.move(filesystem, "test.txt", "not-test.txt")

      assert {:error, _} = Depot.read(filesystem, "test.txt")
      assert {:ok, "Hello World"} = Depot.read(filesystem, "not-test.txt")
    end

    test "user can copy files" do
      filesystem = Depot.Adapter.InMemory.configure(name: InMemoryTest)

      start_supervised(filesystem)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.copy(filesystem, "test.txt", "not-test.txt")

      assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
      assert {:ok, "Hello World"} = Depot.read(filesystem, "not-test.txt")
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
        use Depot.Filesystem,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.WriteTest)

      assert :ok = InMemory.WriteTest.write("test.txt", "Hello World")
    end

    test "user can read from filesystem" do
      defmodule InMemory.ReadTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.ReadTest)

      :ok = InMemory.ReadTest.write("test.txt", "Hello World")

      assert {:ok, "Hello World"} = InMemory.ReadTest.read("test.txt")
    end

    test "user can delete from filesystem" do
      defmodule InMemory.DeleteTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.DeleteTest)

      :ok = InMemory.DeleteTest.write("test.txt", "Hello World")
      :ok = InMemory.DeleteTest.delete("test.txt")

      assert {:error, _} = InMemory.DeleteTest.read("test.txt")
    end

    test "user can move files" do
      defmodule InMemory.MoveTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.MoveTest)

      :ok = InMemory.MoveTest.write("test.txt", "Hello World")
      :ok = InMemory.MoveTest.move("test.txt", "not-test.txt")

      assert {:error, _} = InMemory.MoveTest.read("test.txt")
      assert {:ok, "Hello World"} = InMemory.MoveTest.read("not-test.txt")
    end

    test "user can copy files" do
      defmodule InMemory.CopyTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.CopyTest)

      :ok = InMemory.CopyTest.write("test.txt", "Hello World")
      :ok = InMemory.CopyTest.copy("test.txt", "not-test.txt")

      assert {:ok, "Hello World"} = InMemory.CopyTest.read("test.txt")
      assert {:ok, "Hello World"} = InMemory.CopyTest.read("not-test.txt")
    end

    test "user can list files" do
      defmodule InMemory.ListContentsTest do
        use Depot.Filesystem,
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
