defmodule UtApiError.Details.ErrorInfo do
  @moduledoc """
  错误原因的结构体

  * `reason` - 错误原因，在 `domain` 下唯一
  * `domain` - reason 的逻辑分组
  * `metadata` - 额外的结构化数据，方便程序处理
  """

  defstruct [:reason, :domain, :metadata]

  @type t :: %__MODULE__{
          reason: String.t(),
          domain: String.t() | nil,
          metadata: map() | nil
        }

  defimpl Jason.Encoder do
    def encode(data, opts) do
      %{
        "$type": "ErrorInfo",
        reason: data.reason |> String.upcase(),
        domain: data.domain,
        metadata: data.metadata
      }
      |> Jason.Encode.map(opts)
    end
  end
end
