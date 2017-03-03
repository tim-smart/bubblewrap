defmodule MonEx.Result do
  @moduledoc """
  Result module provides Result type with utility functions.
  """
  require Record

  defmacro ok(res) do
    quote do
      {:ok, unquote(res)}
    end
  end

  defmacro error(err) do
    quote do
      {:error, unquote(err)}
    end
  end

  @typedoc """
  Result type.
  ok(x) or error(err) unwraps into {:ok, x} or {:error, err}
  """
  @type t :: {:ok, term} | {:error, term}

  @doc """
  Returns true if argument is ok(), false if error()
  """
  @spec is_ok(t) :: boolean
  def is_ok(ok(_)), do: true
  def is_ok(error(_)), do: false

  @doc """
  Returns true if argument is error(), false if ok()
  """
  @spec is_error(t) :: boolean
  def is_error(x), do: !is_ok(x)

  @doc """
  Returns value x if argument is ok(x), raises err if error(err)
  """
  @spec unwrap(t) :: term
  def unwrap(ok(x)), do: x
  def unwrap(error(m)), do: raise m

  @doc """
  Returns value if it is ok, or evaluates supplied lambda that expected to return another result.
  """
  @spec fallback(t, (term -> t)) :: t
  def fallback(ok(x), _), do: ok(x)
  def fallback(error(m), f), do: f.(m)

  @doc """
  Filters collection or results so that only oks left
  """
  @spec collect_ok([t]) :: [term]
  def collect_ok(results) do
    results
    |> Enum.filter(&is_ok/1)
    |> Enum.map(&unwrap/1)
  end

  @doc """
  Filters collection or results so that only errors left
  """
  @spec collect_error([t]) :: [term]
  def collect_error(results) do
    results
    |> Enum.filter(&is_error/1)
    |> Enum.map(fn error(m) -> m end)
  end

  defmacro retry(opts \\ [], do: exp) do
    quote do
      n = Keyword.get(unquote(opts), :n, 5)
      delay = Keyword.get(unquote(opts), :delay, 0)
      retry_rec(n, delay, fn -> unquote(exp) end)
    end
  end

  def retry_rec(0, _delay, lambda), do: lambda.()
  def retry_rec(n, delay, lambda) do
    case lambda.() do
      error(_) ->
        :timer.sleep(delay)
        retry_rec(n - 1, delay, lambda)
      ok -> ok
    end
  end
end
