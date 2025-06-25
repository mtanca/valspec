defmodule ValspecTest do
  use ExUnit.Case
  doctest Valspec

  test "greets the world" do
    assert Valspec.hello() == :world
  end
end
