defmodule UTApiError do
  @moduledoc """
  入口模块
  """

  alias UTApiError.Error
  alias UTApiError.DetailsTransformable

  @doc """
  构造 error 结构体

  opts 可选参数：

  * `message` - 自定义的错误信息，给调用者 debug 用
  * `details` - 细节的结构化数据，需要保证它们可以被 `Jason.encode`

  ## Examples

  仅传 code ：

      iex> UTApiError.build(:unauthenticated)
      %UTApiError.Error{
        code: :unauthenticated,
        status: 401,
        message: "The request does not have valid authentication credentials for the operation.",
        details: []
      }

  自定义 message 和 details ：

      iex> UTApiError.build(
      ...>   :failed_precondition,
      ...>   message: "The quota is full",
      ...>   details: [%{reason: "quota_full"}]
      ...> )
      %UTApiError.Error{
        code: :failed_precondition,
        status: 400,
        message: "The quota is full",
        details: [%{reason: "quota_full"}]
      }

  """
  @spec build(code :: atom(), opts :: keyword()) :: Error.t()
  def build(code, opts \\ []) do
    Error.new(code, opts)
  end

  @doc """
  把结构体或结构体列表转换成 detail 的列表

  结构体需要实现 `UTApiError.DetailsTransformable` 协议。本库自带支持以下结构体：

  * `Ecto.Changeset` - 转换成多个 `UTApiError.Details.FieldViolation` 结构体
  * `OpenApiSpex.Cast.Error` - 转换成一个 `UTApiError.Details.FieldViolation` 结构体

  ## Examples

  根据外部数据转换 details ：

      iex(1)> error = %OpenApiSpex.Cast.Error{
      ...(1)>   path: ["a"],
      ...(1)>   reason: :min_items,
      ...(1)>   length: 1,
      ...(1)>   value: []
      ...(1)> }
      %OpenApiSpex.Cast.Error{
        reason: :min_items,
        value: [],
        format: nil,
        type: nil,
        name: nil,
        path: ["a"],
        length: 1,
        meta: %{}
      }
      iex(2)> UTApiError.build(
      ...(2)>   :invalid_argument,
      ...(2)>   message: "custom message",
      ...(2)>   details: UTApiError.transform_details(error)
      ...(2)> )
      %UTApiError.Error{
        code: :invalid_argument,
        status: 400,
        message: "custom message",
        details: [
          %UTApiError.Details.FieldViolation{
            path: ["a"],
            description: "Array length 0 is smaller than minItems: 1"
          }
        ]
      }

  """
  @spec transform_details(data :: struct() | list()) :: [Error.detail()]
  def transform_details(data) when is_list(data) do
    Enum.flat_map(data, fn item ->
      DetailsTransformable.transform(item)
    end)
  end

  def transform_details(data) when is_struct(data) do
    DetailsTransformable.transform(data)
  end
end
