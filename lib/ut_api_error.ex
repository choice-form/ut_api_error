defmodule UTApiError do
  @moduledoc """
  入口模块
  """

  alias UTApiError.Error

  @doc """
  构造 error 结构体

  ## Examples

  仅传 code ：

      iex> UTApiError.build(:unauthenticated)
      %UTApiError.Error{
        code: :unauthenticated,
        status: 401,
        message: "The request does not have valid authentication credentials for the operation."
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
  @spec build(code :: atom(), opts :: keyword()) :: UTApiError.Error.t()
  def build(code, opts \\ []) do
    Error.new(code, opts)
  end
end
