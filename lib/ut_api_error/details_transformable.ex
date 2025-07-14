defprotocol UtApiError.DetailsTransformable do
  alias UtApiError.Error

  @doc """
  把结构体转换成 detail 列表
  """
  @spec transform(data :: struct()) :: [Error.detail()]
  def transform(data)
end

if Code.ensure_loaded?(Ecto.Changeset) do
  defimpl UtApiError.DetailsTransformable, for: Ecto.Changeset do
    alias UtApiError.Details.FieldViolation

    def transform(chset) do
      traverse_errors =
        if Code.ensure_loaded?(PolymorphicEmbed) and
             function_exported?(PolymorphicEmbed, :traverse_errors, 2) do
          &PolymorphicEmbed.traverse_errors/2
        else
          &Ecto.Changeset.traverse_errors/2
        end

      traverse_errors.(chset, fn {msg, opts} ->
        translate_error(msg, opts)
      end)
      |> build_details([], [])
    end

    defp build_details(error_map, path, acc) do
      Enum.reduce(error_map, acc, fn
        # 属性，有多个错误
        {key, [msg | _] = msgs}, acc when is_binary(msg) ->
          for msg <- msgs, reduce: acc do
            acc ->
              item = %FieldViolation{
                path: Enum.reverse([key | path]),
                description: msg
              }

              [item | acc]
          end

        # 1:1 关联
        {key, sub_error_map}, acc when is_map(sub_error_map) ->
          build_details(sub_error_map, [key | path], acc)

        # 1:N 关联
        {key, [%{} | _] = sub_error_maps}, acc ->
          for {sub_error_map, idx} <- Enum.with_index(sub_error_maps),
              map_size(sub_error_map) > 0,
              reduce: acc do
            acc -> build_details(sub_error_map, [idx, key | path], acc)
          end

        _, acc ->
          acc
      end)
    end

    # 把 msg 和 opts 转换成文本信息
    @spec translate_error(msg :: String.t(), opts :: keyword()) :: String.t()
    defp translate_error(msg, opts) do
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
      end)
    end
  end
end

if Code.ensure_loaded?(OpenApiSpex) do
  defimpl UtApiError.DetailsTransformable, for: OpenApiSpex.Cast.Error do
    alias UtApiError.Details.FieldViolation

    def transform(error) do
      [
        %FieldViolation{
          path: error.path,
          description: to_string(error)
        }
      ]
    end
  end
end
