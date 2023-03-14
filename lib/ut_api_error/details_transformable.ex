defprotocol UTApiError.DetailsTransformable do
  alias UTApiError.Error

  @doc """
  把结构体转换成 detail 列表
  """
  @spec transform(data :: struct()) :: [Error.detail()]
  def transform(data)
end
