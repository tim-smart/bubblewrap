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
end
