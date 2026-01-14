defmodule UtApiError.JSONEncoderTest do
  use ExUnit.Case, async: true

  alias UtApiError.Error
  alias UtApiError.Details.ErrorInfo
  alias UtApiError.Details.FieldViolation

  test "JSON.Encoder for UtApiError.Error" do
    error =
      Error.new(:invalid_argument,
        message: "Oops",
        details: [
          %ErrorInfo{
            reason: :some_reason,
            domain: "example",
            metadata: %{"a" => 1}
          },
          %FieldViolation{
            path: [:user, 0, :name],
            description: "can't be blank"
          }
        ]
      )

    json = JSON.encode!(error)

    decoded = JSON.decode!(json)

    assert decoded["code"] == "INVALID_ARGUMENT"
    assert decoded["status"] == 400
    assert decoded["message"] == "Oops"

    assert [
             %{
               "$type" => "ErrorInfo",
               "reason" => "SOME_REASON",
               "domain" => "example",
               "metadata" => %{"a" => 1}
             },
             %{
               "$type" => "FieldViolation",
               "path" => ["user", 0, "name"],
               "description" => "can't be blank"
             }
           ] = decoded["details"]
  end

  test "JSON.Encoder for ErrorInfo" do
    info = %ErrorInfo{reason: :foo, domain: "auth", metadata: %{"k" => "v"}}

    json = JSON.encode!(info)

    assert %{
             "$type" => "ErrorInfo",
             "reason" => "FOO",
             "domain" => "auth",
             "metadata" => %{"k" => "v"}
           } = JSON.decode!(json)
  end

  test "JSON.Encoder for FieldViolation" do
    fv = %FieldViolation{path: [:order, 1, :price], description: "must be positive"}

    json = JSON.encode!(fv)

    assert %{
             "$type" => "FieldViolation",
             "path" => ["order", 1, "price"],
             "description" => "must be positive"
           } = JSON.decode!(json)
  end
end
