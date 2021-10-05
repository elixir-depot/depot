defmodule DepotTest do
  use ExUnit.Case, async: true

  defmacrop assert_in_list(list, match) do
    quote do
      assert Enum.any?(unquote(list), &match?(unquote(match), &1))
    end
  end

  describe "filesystem without own processes" do
    @describetag :tmp_dir

    test "user can write to filesystem", %{tmp_dir: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      assert :ok = Depot.write(filesystem, "test.txt", "Hello World")
    end

    test "user can check if files exist on a filesystem", %{tmp_dir: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")

      assert {:ok, :exists} = Depot.file_exists(filesystem, "test.txt")
      assert {:ok, :missing} = Depot.file_exists(filesystem, "not-test.txt")
    end

    test "user can read from filesystem", %{tmp_dir: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")

      assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
    end

    test "user can delete from filesystem", %{tmp_dir: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.delete(filesystem, "test.txt")

      assert {:error, _} = Depot.read(filesystem, "test.txt")
    end

    test "user can move files", %{tmp_dir: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.move(filesystem, "test.txt", "not-test.txt")

      assert {:error, _} = Depot.read(filesystem, "test.txt")
      assert {:ok, "Hello World"} = Depot.read(filesystem, "not-test.txt")
    end

    test "user can copy files", %{tmp_dir: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")
      :ok = Depot.copy(filesystem, "test.txt", "not-test.txt")

      assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
      assert {:ok, "Hello World"} = Depot.read(filesystem, "not-test.txt")
    end

    test "user can list files", %{tmp_dir: prefix} do
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
    @describetag :tmp_dir

    test "user can write to filesystem", %{tmp_dir: prefix} do
      defmodule Local.WriteTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      assert :ok = Local.WriteTest.write("test.txt", "Hello World")
    end

    test "user can check if files exist on a filesystem", %{tmp_dir: prefix} do
      defmodule Local.FileExistsTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.FileExistsTest.write("test.txt", "Hello World")

      assert {:ok, :exists} = Local.FileExistsTest.file_exists("test.txt")
      assert {:ok, :missing} = Local.FileExistsTest.file_exists("not-test.txt")
    end

    test "user can read from filesystem", %{tmp_dir: prefix} do
      defmodule Local.ReadTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.ReadTest.write("test.txt", "Hello World")

      assert {:ok, "Hello World"} = Local.ReadTest.read("test.txt")
    end

    test "user can delete from filesystem", %{tmp_dir: prefix} do
      defmodule Local.DeleteTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.Local,
          prefix: prefix
      end

      :ok = Local.DeleteTest.write("test.txt", "Hello World")
      :ok = Local.DeleteTest.delete("test.txt")

      assert {:error, _} = Local.DeleteTest.read("test.txt")
    end

    test "user can move files", %{tmp_dir: prefix} do
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

    test "user can copy files", %{tmp_dir: prefix} do
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

    test "user can list files", %{tmp_dir: prefix} do
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

    test "user can check if files exist on a filesystem" do
      filesystem = Depot.Adapter.InMemory.configure(name: InMemoryTest)

      start_supervised(filesystem)

      :ok = Depot.write(filesystem, "test.txt", "Hello World")

      assert {:ok, :exists} = Depot.file_exists(filesystem, "test.txt")
      assert {:ok, :missing} = Depot.file_exists(filesystem, "not-test.txt")
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

    test "user can check if files exist on a filesystem" do
      defmodule InMemory.FileExistsTest do
        use Depot.Filesystem,
          adapter: Depot.Adapter.InMemory
      end

      start_supervised(InMemory.FileExistsTest)

      :ok = InMemory.FileExistsTest.write("test.txt", "Hello World")

      assert {:ok, :exists} = InMemory.FileExistsTest.file_exists("test.txt")
      assert {:ok, :missing} = InMemory.FileExistsTest.file_exists("not-test.txt")
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
    @describetag :tmp_dir

    setup %{tmp_dir: prefix} do
      filesystem = Depot.Adapter.Local.configure(prefix: prefix)
      {:ok, filesystem: filesystem}
    end

    test "reads configuration from :otp_app", context do
      configuration = [
        adapter: Depot.Adapter.Local,
        prefix: "ziKK7t5LzV5XiJjYh30KxCLorRXqLwwEnZYJ"
      ]

      Application.put_env(:depot_test, DepotTest.AdhocFilesystem, configuration)

      defmodule AdhocFilesystem do
        use Depot.Filesystem, otp_app: :depot_test
      end

      {_module, module_config} = DepotTest.AdhocFilesystem.__filesystem__()

      assert module_config.prefix == "ziKK7t5LzV5XiJjYh30KxCLorRXqLwwEnZYJ"
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

  describe "copying between different filesystems" do
    @describetag :tmp_dir

    setup %{tmp_dir: prefix} do
      prefix_a = Path.join(prefix, "a")
      prefix_b = Path.join(prefix, "b")

      {:ok, prefixes: [prefix_a, prefix_b]}
    end

    test "direct copy - same adapter", %{prefixes: [prefix_a, prefix_b]} do
      filesystem_a = Depot.Adapter.Local.configure(prefix: prefix_a)
      filesystem_b = Depot.Adapter.Local.configure(prefix: prefix_b)

      :ok = Depot.write(filesystem_a, "test.txt", "Hello World")

      assert :ok =
               Depot.copy_between_filesystem(
                 {filesystem_a, "test.txt"},
                 {filesystem_b, "test.txt"}
               )

      assert {:ok, :exists} = Depot.file_exists(filesystem_b, "test.txt")
    end

    test "indirect copy - same adapter" do
      filesystem_a = Depot.Adapter.InMemory.configure(name: InMemoryTest.A)
      filesystem_b = Depot.Adapter.InMemory.configure(name: InMemoryTest.B)

      filesystem_a |> Supervisor.child_spec(id: :a) |> start_supervised()
      filesystem_b |> Supervisor.child_spec(id: :b) |> start_supervised()

      :ok = Depot.write(filesystem_a, "test.txt", "Hello World")

      assert :ok =
               Depot.copy_between_filesystem(
                 {filesystem_a, "test.txt"},
                 {filesystem_b, "test.txt"}
               )

      assert {:ok, :exists} = Depot.file_exists(filesystem_b, "test.txt")
    end

    test "different adapter", %{prefixes: [prefix_a | _]} do
      filesystem_a = Depot.Adapter.Local.configure(prefix: prefix_a)
      filesystem_b = Depot.Adapter.InMemory.configure(name: InMemoryTest.B)

      start_supervised(filesystem_b)

      :ok = Depot.write(filesystem_a, "test.txt", "Hello World")

      assert :ok =
               Depot.copy_between_filesystem(
                 {filesystem_a, "test.txt"},
                 {filesystem_b, "test.txt"}
               )

      assert {:ok, :exists} = Depot.file_exists(filesystem_b, "test.txt")
    end
  end
end
