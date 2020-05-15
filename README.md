# Depot

![Elixir CI](https://github.com/LostKobrakai/depot/workflows/Elixir%20CI/badge.svg)  
[Hex Package](https://hex.pm/depot) | 
[Online Documentation](https://hexdocs.pm/depot).

<!-- MDOC !-->

Depot is a filesystem abstraction for elixir providing a unified interface over many implementations. It allows you to swap out filesystems on the fly without needing to rewrite all of your application code in the process. It can eliminate vendor-lock in, reduce technical debt, and improve the testability of your code.

This library is based on the ideas of [flysystem](http://flysystem.thephpleague.com/), which is a PHP library providing similar functionality.

## Examples

```elixir
defmodule LocalFileSystem do
  use Depot,
    adapter: Depot.Adapter.Local,
    prefix: prefix
end

LocalFileSystem.write("test.txt", "Hello World")
{:ok, "Hello World"} = LocalFileSystem.read("test.txt")
```

<!-- MDOC !-->

## Installation

The package can be installed by adding `depot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:depot, "~> 0.1.0"}
  ]
end
```
