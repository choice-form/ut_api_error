defmodule UtApiError.Details.FieldViolation do
  @moduledoc """
  请求参数错误的结构体，标识哪一个字段出错
  """

  defstruct [:path, :description]

  @type t :: %__MODULE__{
          path: [path_key()],
          description: String.t()
        }

  @type path_key :: String.t() | integer()

  defimpl Jason.Encoder do
    def encode(data, opts) do
      data
      |> Map.take([:path, :description])
      |> Map.put(:"$type", "FieldViolation")
      |> Jason.Encode.map(opts)
    end
  end
end
