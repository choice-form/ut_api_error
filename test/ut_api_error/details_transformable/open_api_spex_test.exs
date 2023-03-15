defmodule UTApiError.DetailsTransformable.OpenApiSpexTest do
  use ExUnit.Case, async: true

  alias UTApiError.DetailsTransformable
  alias UTApiError.Details.FieldViolation

  test "transform error" do
    error = %OpenApiSpex.Cast.Error{
      path: ["a", "b"],
      reason: :min_items,
      length: 1,
      value: []
    }

    assert [detail] = DetailsTransformable.transform(error)

    assert detail == %FieldViolation{
             path: ["a", "b"],
             description: "Array length 0 is smaller than minItems: 1"
           }
  end
end
