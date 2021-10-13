defmodule Bubblewrap do
  @moduledoc ~S"""
  Bubblewrap implements two most common monadic data types:

    * `Bubblewrap.Result` - container for a result of operation or error.
      Result can be created using a constructor macro: `{:ok, value}` or `{:error, e}`,
      where underlying structure is a tuple: `{:ok, value}` or `{:error, e}` respectively.

    * `Bubblewrap.Option` - container for a value that might be present or missing.
      Simple wrapper around a value that could be `nil`.

    * `Bubblewrap` - collection of utility functions to work with both of these types.

  ## Result

  Result type fits perfectly with idiomatic Erlang/Elixir return values.
  When some library function returns either `{:ok, val}` or `{:error, err}`,
  you can use functions provided by Bubblewrap right away. The most typical example,
  where Bubblewrap shines, is a pipeline, where each operation can fail. Normally
  this would be organized in a form of nested case expressions:

      final = case op1(x) do
        {:ok, res1} ->
          case op2(res1) do
            {:ok, res2} -> op3(res2)
            {:error, e} -> {:error, e}
          end
        {:error, e} -> {:error, e}
      end

  With Bubblewrap you can do the same using `flat_map` operation:

      final = op1(x) |> flat_map(&op2/1) |> flat_map(&op3/1)

  Once any of the operations returns `{:error, e}`, following operations
  are skipped and the error is returned. You can either do something
  based on pattern matching or provide a fallback (can be a function or a default value).

      case final do
        {:ok, value} -> IO.puts(value)
        {:error, e} -> IO.puts("Oh, no, the error occured!")
      end

      final |> fallback({:ok, "No problem, I got it"})

  ## Option

  Option type wraps the value. If value is present, it's `value`,
  if it's missing, `nil` is used instead. With Option type, you can use the
  same set of functions, such as `map`, `flat_map`, etc.

      find_user(id)
      |> map(&find_posts_by_user/1)

  This will only request for posts if the user was found.

  See docs per Result and Option modules for details.
  """
  alias Bubblewrap.{Option, Result}
  @typep m(a, b) :: Option.t(a) | Result.t(a, b)

  @doc """
  Transforms the content of monadic type.
  Function is applied only if it's `ok` or not nil.
  Otherwise value stays intact.

  Example:
      f = fn (x) ->
        x * 2
      end
      5 |> map(f) == 10
      nil |> map(f) == nil
  """
  @spec map(m(a, b), (a -> c)) :: m(c, b) when a: any, b: any, c: any
  def map({:ok, x}, f) when is_function(f, 1), do: {:ok, f.(x)}
  def map({:error, m}, f) when is_function(f, 1), do: {:error, m}

  def map(nil, f) when is_function(f, 1), do: nil
  def map(x, f) when is_function(f, 1), do: f.(x)

  @doc """
  Applies function that returns monadic type itself to the content
  of the monadic type. This is useful in a chain of operations, where
  argument to the next op has to be unwrapped to proceed.

  Example:
      inverse = fn (x) ->
        if x == 0 do
          nil
        else
          1/x
        end
      5 |> flat_map(f) == 1/5
      0 |> flat_map(f) == nil
  """
  @spec flat_map(m(a, b), (a -> m(c, b))) :: m(c, b) when a: any, b: any, c: any
  def flat_map({:ok, x}, f) when is_function(f, 1), do: f.(x)
  def flat_map({:error, m}, f) when is_function(f, 1), do: {:error, m}

  def flat_map(nil, f) when is_function(f, 1), do: nil
  def flat_map(x, f) when is_function(f, 1), do: f.(x)

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
  @spec foreach(m(a, b), (a -> no_return)) :: m(a, b) when a: any, b: any
  def foreach({:ok, x} = res, f) when is_function(f, 1),
    do:
      (
        f.(x)
        res
      )

  def foreach({:error, _} = z, _), do: z

  def foreach(nil = z, _), do: z

  def foreach(x = res, f) when is_function(f, 1),
    do:
      (
        f.(x)
        res
      )
end
