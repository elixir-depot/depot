defmodule Depot.RelativePathTest do
  use ExUnit.Case, async: true
  alias Depot.RelativePath

  test "relative?" do
    assert RelativePath.relative?("path/to/dir")
    refute RelativePath.relative?("/path/to/dir")
    refute RelativePath.relative?("C:/path/to/dir")
    refute RelativePath.relative?("//path/to/dir")
  end

  test "expand" do
    assert {:ok, "path/to/dir"} = RelativePath.expand("path/to/dir")
    assert {:ok, "to/dir"} = RelativePath.expand("path/../to/dir")
    assert {:error, :traversal} = RelativePath.expand("../path/to/dir")
    assert {:error, :traversal} = RelativePath.expand("path/../../path/to/dir")
    assert {:error, :traversal} = RelativePath.expand("path/../path/../../to/dir")
    assert {:error, :traversal} = RelativePath.expand("path/../path/to/../../../")
  end

  test "join_prefix" do
    assert "/path/to/dir" = RelativePath.join_prefix("/", "path/to/dir")
    assert "/path/to/dir/" = RelativePath.join_prefix("/", "path/to/dir/")
    assert "/prefix/path/to/dir" = RelativePath.join_prefix("/prefix", "path/to/dir")
    assert "/prefix/path/to/dir" = RelativePath.join_prefix("/prefix/", "path/to/dir")
    assert "C:/path/to/dir" = RelativePath.join_prefix("C:/", "path/to/dir")
    assert "C:/prefix/path/to/dir" = RelativePath.join_prefix("C:/prefix", "path/to/dir")
    assert "C:/prefix/path/to/dir" = RelativePath.join_prefix("C:/prefix/", "path/to/dir")
    assert "//prefix/path/to/dir" = RelativePath.join_prefix("//prefix/", "path/to/dir")
  end

  test "strip_prefix" do
    assert "path/to/dir" = RelativePath.strip_prefix("/", "/path/to/dir")
    assert "path/to/dir" = RelativePath.strip_prefix("/prefix", "/prefix/path/to/dir")
    assert "path/to/dir" = RelativePath.strip_prefix("/prefix/", "/prefix/path/to/dir")
    assert "path/to/dir" = RelativePath.strip_prefix("C:/", "C:/path/to/dir")
    assert "path/to/dir" = RelativePath.strip_prefix("C:/prefix", "C:/prefix/path/to/dir")
    assert "path/to/dir" = RelativePath.strip_prefix("C:/prefix/", "C:/prefix/path/to/dir")
    assert "path/to/dir" = RelativePath.strip_prefix("//prefix/", "//prefix/path/to/dir")
  end
end
