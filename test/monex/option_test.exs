defmodule BubblewrapOptionTest do
  use ExUnit.Case
  doctest Bubblewrap.Option, import: true
  import Bubblewrap.Option
  import Bubblewrap

  test "is_some" do
    assert is_some(5)
    refute is_some(nil)
  end

  test "is_none" do
    assert is_none(nil)
    refute is_none(5)
  end

  test "or_else" do
    assert 5 |> or_else(1) == 5
    assert nil |> or_else(1) == 1
    assert nil |> or_else(fn -> 4 end) == 4
  end

  test "get" do
    assert 5 |> get == 5

    assert_raise RuntimeError, "Can't get value of nil", fn ->
      get(nil)
    end
  end

  test "map" do
    assert 5 |> map(&(&1 * 2)) == 10
    assert nil |> map(&(&1 * 2)) == nil
  end

  test "flat_map" do
    assert 5 |> flat_map(&(&1 * 2)) == 10
    assert nil |> flat_map(&(&1 * 2)) == nil
  end

  test "foreach" do
    me = self()
    res = 5 |> foreach(&send(me, &1))
    assert res == 5
    res = nil |> foreach(fn -> send(me, "WTF") end)
    assert res == nil
    :timer.sleep(1)
    assert_received 5
    refute_received "WTF"
  end
end
