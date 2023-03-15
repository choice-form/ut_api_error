defmodule UTApiError.Error do
  @data [
          {:invalid_argument, 400, "The client specified an invalid argument."},
          {:failed_precondition, 400,
           "The operation was rejected because the system is not in a state required for the operation's execution."},
          {:out_of_range, 400, "The operation was attempted past the valid range."},
          {:unauthenticated, 401,
           "The request does not have valid authentication credentials for the operation."},
          {:permission_denied, 403,
           "The caller does not have permission to execute the specified operation."},
          {:not_found, 404, "Some requested entity was not found."},
          {:already_exists, 409, "The entity that a client attempted to create already exists."},
          {:aborted, 409, "The operation was aborted."},
          {:resource_exhausted, 429, "Some resource has been exhausted."},
          {:cancelled, 499, "The operation was cancelled, typically by the caller."},
          {:internal, 500, "Internal errors."},
          {:unknown, 500, "Unknown error."},
          {:data_loss, 500, "Unrecoverable data loss or corruption."},
          {:unimplemented, 501,
           "The operation is not implemented or is not supported/enabled in this service."},
          {:unavailable, 503, "The service is currently unavailable."},
          {:deadline_exceeded, 504, "The deadline expired before the operation could complete."}
        ]
        |> Enum.map(fn {code, status, message} ->
          %{code: code, status: status, message: message}
        end)

  @data_map Map.new(@data, &{&1.code, &1})

  @codes Enum.map(@data, & &1.code)

  defstruct [:status, :code, :message, :details]

  @type t :: %__MODULE__{
          code: atom(),
          status: pos_integer(),
          message: String.t(),
          details: [detail()]
        }

  @type detail :: struct() | map()

  defimpl Jason.Encoder do
    def encode(error, opts) do
      Jason.Encode.map(
        %{
          code: error.code |> to_string() |> String.upcase(),
          status: error.status,
          message: error.message,
          details: error.details
        },
        opts
      )
    end
  end

  @doc """
  初始化 Error
  """
  def new(code, opts \\ []) do
    unless code in @codes do
      raise ArgumentError, "invalid code. got: #{inspect(code)}"
    end

    if opts[:status] do
      raise ArgumentError, ":status is not allowed in opts keyword"
    end

    data = Map.fetch!(@data_map, code)

    %__MODULE__{
      code: code,
      status: data.status,
      message: data.message,
      details: []
    }
    |> then(&struct!(&1, opts))
  end
end
