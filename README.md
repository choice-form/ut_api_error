# UTApiError

Choiceform 的 REST API 处理错误的标准库。

## 本地开发

本项目的必备依赖只有 `jason` ，其他都是可选的。

测试：

```bash
mix test
```

## 

## 其他项目集成

下面以 Phoenix 项目举例子，但 `ut_api_error` 并不依赖任何 web 框架，集成的整体思路也是一致的。

在 `mix.exs` 中添加依赖：

```elixir
def deps do
  [
    # 项目应该始终用 tag 版本，避免造成破坏
    {:ut_api_error, git: "git@github.com:choice-form/ut_api_error.git", tag: "v0.1.0"}
    # 本地开发以及连调推荐用 path
    # {:ut_api_error, git: "git@github.com:choice-form/ut_api_error.git"}
    # {:ut_api_error, path: "/path/to/ut_api_error"}
  ]
end
```

### UTApiError 基础用法

具体看 `UTApiError` 模块文档。你基本只需要 `build` 和 `transform_details` 。

### 通用 API 错误的处理

这些错误通常有：

* 未验证 - 使用 code `:unauthenticated`
* 未授权 - 使用 code `:permission_denied`
* 资源找不到 - 使用 code `:not_found`
* 请求参数校验错误 - 使用 code `:invalid_argument`

Phoenix 项目应该在 controller action 层面返回统一的 `{:error, struct}` 结构，然后在 `FallbackController` 中处理：

```elixir
defmodule YourAppWeb.FallbackController do
  # 统一处理 UTApiError.Error
  def call(conn, {:error, %UTApiError.Error{} = error}) do
    render_error(conn, error)
  end

  # 统一处理 Ecto.Changeset
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    # 构建 UTApiError.Error 结构体，并把 changeset 转换成 details 结构体列表
    error =
      UTApiError.build(:invalid_argument,
        details: UTApiError.transform_details(changeset)
      )

    render_error(conn, error)
  end

  # 统一处理渲染，生成符合 API 规范的结构
  defp render_error(conn, error) do
    conn
    |> put_status(error.status)
    # Phoenix 1.7 使用 put_view(json: DemoApiErrorWeb.ErrorJSON)
    |> put_view(YourAppWeb.ErrorView)
    |> render(:api_error,
      request_id: get_request_id(conn),
      error: error
    )
  end

  # 获取 request_id ，为放入 response 做准备
  defp get_request_id(conn) do
    case get_resp_header(conn, "x-request-id") do
      [request_id] -> request_id
      _ -> nil
    end
  end
end
```

对应的 `ErrorJSON` ：

```elixir
defmodule YourAppWeb.ErrorView do
  def render("error.json", %{request_id: request_id, error: api_error}) do
    # api_error 是 UTApiError.Error 结构体
    # 因为实现了 Jason.Encoder 协议，可以被自动转换成 JSON
    %{request_id: request_id, error: api_error}
  end
end
```

### 业务逻辑错误错误

这些错误一般是每个应用专有的，错误需求包括但不限于：

- 定义业务错误代码
- 定义额外的结构化数据，方便调用者处理

这需要在 controller action 里单独构建 `UTApiError.Error` 。大多数情况下它们应该使用 code `:failed_precondition` ，并把细节数据放到 details 中。


```elixir
defmodule YourAppWeb.WorkflowController do
  def publish(conn, _) do
    with :ok <- Context.publish(conn) do
      render_ok()
    else
      {:error, {:publish_error, _reason}} ->
        # 把 context 中的错误转换成 UTApiError.Error 结构体
        # 业务错误的 code 和 details 需要自行决定
        api_error = UTApiError.build(
          :failed_precondition,
          # API 规范对 details 的定义是 array<object>
          details: [
            # detail 可以是 map 或结构体，结构体需要实现 Jason.Encoder 协议
            # ErrorInfo 是通用的带业务错误代码 (reason) 的数据结构
            %UTApiError.Details.ErrorInfo{
              reason: "business_code"
            }
          ]
        )

        # 返回统一结构，渲染仍然交给 FallbackController 处理
        {:error, api_error}
    end
  end
end
```
