defmodule UTApiError.Details.FieldViolation do
  @moduledoc """
  请求参数错误的结构体，标识哪一个字段出错
  """

  defstruct [:path, :description]

  @type t :: %__MODULE__{
          path: [path_key()],
          description: String.t()
        }

  @type path_key :: String.t() | integer()
end
