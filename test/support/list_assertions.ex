defmodule Depot.ListAssertions do
  defmacro assert_in_list(list, match) do
    quote do
      assert Enum.any?(unquote(list), &match?(unquote(match), &1))
    end
  end

  defmacro refute_in_list(list, match) do
    quote do
      refute Enum.any?(unquote(list), &match?(unquote(match), &1))
    end
  end
end