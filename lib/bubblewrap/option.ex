defmodule Bubblewrap.Option do
  @moduledoc """
  Option module provides Option type with utility functions.
  """

  alias Bubblewrap.Result

  @typedoc """
  Option type.
  """
  @type t(a) :: a | nil

  @doc """
  Returns true if argument is not nil

  ## Examples
      iex> is_some(5)
      true

      iex> is_some(nil)
      false
  """
  @spec is_some(t(any)) :: boolean
  def is_some(nil), do: false
  def is_some(_), do: true

  @doc """
  Returns true if argument is nil

  ## Examples
      iex> is_none(nil)
      true

      iex> is_none(5)
      false
  """
  @spec is_none(t(any)) :: boolean
  def is_none(nil), do: true
  def is_none(_), do: false

  @doc """
  Returns option if argument is not nil, second argument which has to be option
  otherwise. Executes function, if it's supplied.

  ## Examples
      iex> 5 |> or_else(2)
      5

      iex> nil |> or_else(2)
      2

      iex> nil |> or_else(fn -> 1 end)
      1
  """
  @spec or_else(t(a), t(a) | (() -> t(a))) :: t(a) when a: any
  def or_else(nil, f) when is_function(f, 0) do
    f.()
  end

  def or_else(nil, z), do: z

  def or_else(x, _), do: x

  @doc """
  Returns content of option if argument is not nil, raises otherwise

  ## Examples
      iex> 5 |> get
      5
  """
  @spec get(t(a)) :: a when a: any
  def get(nil), do: raise("Can't get value of nil")
  def get(x), do: x

  @doc """
  Converts an Option into Result if value is present, otherwise returns second
  argument wrapped in `error()`.

  ## Examples
      iex> 5 |> ok_or_else(2)
      {:ok, 5}

      ...> nil |> ok_or_else(:missing_value)
      {:error, :missing_value}

      ...> nil |> ok_or_else(fn -> :oh_no end)
      {:error, :oh_no}
  """
  @spec ok_or_else(t(a), err | (() -> err)) :: Result.t(a, err) when a: any, err: any
  def ok_or_else(nil, f) when is_function(f, 0) do
    {:error, f.()}
  end

  def ok_or_else(nil, z), do: {:error, z}
  def ok_or_else(x, _), do: {:ok, x}

  @doc """
  Transforms the content of monadic type.
  Function is applied only if it's not nil.
  Otherwise value stays intact.

  Example:
      f = fn (x) ->
        x * 2
      end
      5 |> map(f) == 10
      nil |> map(f) == nil
  """
  @spec map(t(a), (a -> b)) :: t(b) when a: any, b: any
  def map(nil, f) when is_function(f, 1), do: nil

  def map(x, f) when is_function(f, 1) do
    case f.(x) do
      nil -> raise "Bubblewrap.Option.map can not return nil"
      b -> b
    end
  end

  @doc """
  Applies function that returns monadic type itself to the content
  of the monadic type. This is useful in a chain of operations, where
  argument to the next op has to be unwrapped to proceed.

  Example:
      f = fn (x) ->
        if x == 0 do
          nil
        else
          1/x
        end
      5 |> flat_map(f) == 1/5
      0 |> flat_map(f) == nil
  """
  @spec flat_map(t(a), (a -> t(b))) :: t(b) when a: any, b: any
  def flat_map(nil, _), do: nil
  def flat_map(x, f) when is_function(f, 1), do: f.(x)

  @doc """
  Applies function that returns a boolean using the value of the monadic type.
  If false, the value will be set to nil.

  Example:
      f = fn (x) ->
          x == 0
        end
      5 |> filter(f) == 5
      0 |> filter(f) == nil
  """
  @spec filter(t(a), (a -> boolean())) :: t(a) when a: any
  def filter(nil, _), do: nil

  def filter(a, f) when is_function(f, 1) do
    case f.(a) do
      true -> a
      false -> nil
    end
  end

  @doc """
  Performs a calculation with the content of monadic container and returns
  the argument intact. Even though the convention says to return nothing (Unit)
  this one passes value along for convenience — this way we can perform more
  than one operation.

      5
      |> foreach(fn x -> IO.inspect(x) end)
      |> foreach(fn x -> IO.inspect(2 * x) end)

  This will print: 5 10
  """
  @spec foreach(t(a), (a -> no_return)) :: t(a) when a: any
  def foreach(nil = z, _), do: z

  def foreach(x = res, f) when is_function(f, 1),
    do:
      (
        f.(x)
        res
      )
end
