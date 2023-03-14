defmodule UTApiError.DetailsTransformable.EctoTest do
  use ExUnit.Case, async: true

  alias UTApiError.DetailsTransformable
  alias UTApiError.Details.FieldViolation

  defmodule DemoOrderDetail do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :description, :string
    end

    def changeset(chset, params) do
      chset
      |> cast(params, [:description])
      |> validate_required([:description])
    end
  end

  defmodule DemoTag do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
    end

    def changeset(chset, params) do
      chset
      |> cast(params, [:name])
      |> validate_required([:name])
    end
  end

  defmodule DemoUser do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field :name, :string
      field :age, :integer
    end

    def changeset(user, params) do
      user
      |> cast(params, [:name, :age])
      |> validate_required([:name, :age])
      |> validate_number(:age, greater_than: 18)
    end
  end

  defmodule DemoLineItem do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :name, :string
      field :price, :integer
    end

    def changeset(line_item, params) do
      line_item
      |> cast(params, [:name, :price])
      |> validate_required([:name, :price])
      |> validate_number(:price, greater_than: 0)
    end
  end

  defmodule DemoOrder do
    use Ecto.Schema
    import Ecto.Changeset

    schema "orders" do
      field :name, :string
      field :price, :integer
      field :type, Ecto.Enum, values: [:a, :b]

      has_one :buyer, DemoUser
      has_many :items, DemoLineItem

      embeds_one :detail, DemoOrderDetail
      embeds_many :tags, DemoTag
    end

    def changeset(params) do
      changeset(%__MODULE__{}, params)
    end

    def changeset(order, params) do
      order
      |> cast(params, [:name, :price, :type])
      |> cast_assoc(:buyer)
      |> cast_assoc(:items)
      |> cast_embed(:detail)
      |> cast_embed(:tags)
      |> validate_required([:name, :price])
      |> validate_length(:name, max: 7)
      |> validate_format(:name, ~r/^[a-zA-Z0-9\s]+$/)
      |> validate_number(:price, greater_than: 0)
      |> validate_length(:items, min: 1, max: 2)
    end
  end

  test "invalid params for top-level schema errors" do
    chset =
      DemoOrder.changeset(%{
        name: "!!!!!!!!!",
        price: "abc",
        type: "c"
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:name],
               description: "has invalid format"
             },
             %FieldViolation{
               path: [:name],
               description: "should be at most 7 character(s)"
             },
             %FieldViolation{
               path: [:price],
               description: "is invalid"
             },
             %FieldViolation{
               path: [:type],
               description: "is invalid"
             }
           ]
  end

  defp sort_field_violations(details) do
    Enum.sort_by(details, &{&1.path, &1.description})
  end
end
