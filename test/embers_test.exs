defmodule EmbersTest do
  use ExUnit.Case
  doctest Embers

  test "greets the world" do
    assert Embers.hello() == :world
  end
end
