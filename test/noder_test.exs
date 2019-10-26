defmodule NoderTest do
  use ExUnit.Case
  doctest Noder

  test "greets the world" do
    assert Noder.hello() == :world
  end
end
