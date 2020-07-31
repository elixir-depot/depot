defmodule Depot.AdapterTest do
  defmacro assert_in_list(list, match) do
    quote do
      assert Enum.any?(unquote(list), &match?(unquote(match), &1))
    end
  end

  defp tests do
    quote do
      test "user can write to filesystem", %{filesystem: filesystem} do
        assert :ok = Depot.write(filesystem, "test.txt", "Hello World")
      end

      test "user can overwrite a file on the filesystem", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Old text")
        assert :ok = Depot.write(filesystem, "test.txt", "Hello World")
        assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
      end

      test "user can check if files exist on a filesystem", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Hello World")

        assert {:ok, :exists} = Depot.file_exists(filesystem, "test.txt")
        assert {:ok, :missing} = Depot.file_exists(filesystem, "not-test.txt")
      end

      test "user can read from filesystem", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Hello World")

        assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
      end

      test "user can stream from filesystem", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Hello World")

        assert {:ok, stream} = Depot.read_stream(filesystem, "test.txt")

        assert Enum.into(stream, <<>>) == "Hello World"
      end

      test "user can stream in a certain chunk size", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Hello World")

        assert {:ok, stream} = Depot.read_stream(filesystem, "test.txt", chunk_size: 2)

        assert ["He" | _] = Enum.into(stream, [])
      end

      test "user can try to read a non-existing file from filesystem", %{filesystem: filesystem} do
        assert {:error, :enoent} = Depot.read(filesystem, "test.txt")
      end

      test "user can delete from filesystem", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Hello World")
        :ok = Depot.delete(filesystem, "test.txt")

        assert {:error, _} = Depot.read(filesystem, "test.txt")
      end

      test "user can delete a non-existing file from filesystem", %{filesystem: filesystem} do
        assert :ok = Depot.delete(filesystem, "test.txt")
      end

      test "user can move files", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Hello World")
        :ok = Depot.move(filesystem, "test.txt", "not-test.txt")

        assert {:error, _} = Depot.read(filesystem, "test.txt")
        assert {:ok, "Hello World"} = Depot.read(filesystem, "not-test.txt")
      end

      test "user can try to move a non-existing file", %{filesystem: filesystem} do
        assert {:error, :enoent} = Depot.move(filesystem, "test.txt", "not-test.txt")
      end

      test "user can copy files", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Hello World")
        :ok = Depot.copy(filesystem, "test.txt", "not-test.txt")

        assert {:ok, "Hello World"} = Depot.read(filesystem, "test.txt")
        assert {:ok, "Hello World"} = Depot.read(filesystem, "not-test.txt")
      end

      test "user can try to copy a non-existing file", %{filesystem: filesystem} do
        assert {:error, :enoent} = Depot.copy(filesystem, "test.txt", "not-test.txt")
      end

      test "user can list files", %{filesystem: filesystem} do
        :ok = Depot.write(filesystem, "test.txt", "Hello World")
        :ok = Depot.write(filesystem, "test-1.txt", "Hello World")

        {:ok, list} = Depot.list_contents(filesystem, ".")

        assert length(list) == 2
        Depot.AdapterTest.assert_in_list(list, %Depot.Stat.File{name: "test.txt"})
        Depot.AdapterTest.assert_in_list(list, %Depot.Stat.File{name: "test-1.txt"})
      end
    end
  end

  defmacro adapter_test(block) do
    quote do
      describe "common adapter tests" do
        setup unquote(block)

        unquote(tests())
      end
    end
  end

  defmacro adapter_test(context, block) do
    quote do
      describe "common adapter tests" do
        setup unquote(context), unquote(block)

        unquote(tests())
      end
    end
  end
end
