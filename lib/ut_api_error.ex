defmodule UTApiError do
  @moduledoc """
  入口模块
  """

  alias UTApiError.Error
  alias UTApiError.DetailsTransformable

  @doc """
  构造 error 结构体

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

  结构体需要实现 `UTApiError.DetailsTransformable` 协议。
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
