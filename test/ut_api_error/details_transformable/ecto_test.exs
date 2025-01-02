defmodule UtApiError.DetailsTransformable.EctoTest do
  use ExUnit.Case, async: true

  alias UtApiError.DetailsTransformable
  alias UtApiError.Details.FieldViolation

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
      embeds_many :tags, DemoTag
    end

    def changeset(line_item, params) do
      line_item
      |> cast(params, [:name, :price])
      |> cast_embed(:tags)
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

  defmodule DemoEmail do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :address, :string
      field :confirmed, :boolean
    end

    def changeset(email, params) do
      email
      |> cast(params, [:address, :confirmed])
      |> validate_required(:address)
      |> validate_length(:address, min: 4)
    end
  end

  defmodule DemoSMS do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :number, :string
    end

    def changeset(sms, params) do
      sms
      |> cast(params, [:number])
      |> validate_required(:number)
    end
  end

  defmodule DemoReminder do
    use Ecto.Schema
    import Ecto.Changeset
    import PolymorphicEmbed

    embedded_schema do
      field :text, :string

      polymorphic_embeds_one :channel,
        types: [
          sms: DemoSMS,
          email: DemoEmail
        ],
        type_field: :type,
        on_type_not_found: :raise,
        on_replace: :update

      polymorphic_embeds_many :channels,
        types: [
          sms: DemoSMS,
          email: DemoEmail
        ],
        type_field: :type,
        on_type_not_found: :raise,
        on_replace: :delete
    end

    def changeset(params) do
      %__MODULE__{}
      |> cast(params, [:text])
      |> validate_required(:text)
      |> cast_polymorphic_embed(:channel)
      |> cast_polymorphic_embed(:channels)
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

  test "invalid params for relationship field errors" do
    chset =
      DemoOrder.changeset(%{
        name: "order 1",
        price: 1,
        items: [
          %{name: "item 1", price: 1},
          %{name: "item 2", price: 1},
          %{name: "item 3", price: 1}
        ]
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:items],
               description: "should have at most 2 item(s)"
             }
           ]
  end

  test "invalid params for relationship (one) errors" do
    chset =
      DemoOrder.changeset(%{
        name: "order 1",
        price: 1,
        buyer: %{
          name: "",
          age: 16
        }
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:buyer, :age],
               description: "must be greater than 18"
             },
             %FieldViolation{
               path: [:buyer, :name],
               description: "can't be blank"
             }
           ]
  end

  test "invalid params for relationship (many) errors" do
    chset =
      DemoOrder.changeset(%{
        name: "order 1",
        price: 1,
        items: [
          %{name: "Item 1", price: 1},
          %{name: "", price: ""},
          %{name: "item 3", price: -1}
        ]
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:items, 1, :name],
               description: "can't be blank"
             },
             %FieldViolation{
               path: [:items, 1, :price],
               description: "can't be blank"
             },
             %FieldViolation{
               path: [:items, 2, :price],
               description: "must be greater than 0"
             }
           ]
  end

  test "invalid params for embed (one) errors" do
    chset =
      DemoOrder.changeset(%{
        name: "order 1",
        price: 1,
        detail: %{
          description: ""
        }
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:detail, :description],
               description: "can't be blank"
             }
           ]
  end

  test "invalid params for embed (many) errors" do
    chset =
      DemoOrder.changeset(%{
        name: "order 1",
        price: 1,
        tags: [
          %{name: "Tag 1"},
          %{name: ""}
        ]
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:tags, 1, :name],
               description: "can't be blank"
             }
           ]
  end

  test "invalid params for embed (many) nested in relationship" do
    chset =
      DemoOrder.changeset(%{
        name: "order 1",
        price: 1,
        items: [
          %{
            name: "",
            price: 1,
            tags: [
              %{name: "Tag 1"},
              %{name: ""}
            ]
          }
        ]
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:items, 0, :name],
               description: "can't be blank"
             },
             %FieldViolation{
               path: [:items, 0, :tags, 1, :name],
               description: "can't be blank"
             }
           ]
  end

  test "invalid params for polymorphic embed (one)" do
    chset =
      DemoReminder.changeset(%{
        text: "",
        channel: %{
          type: "sms",
          number: ""
        }
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:channel, :number],
               description: "can't be blank"
             },
             %FieldViolation{
               path: [:text],
               description: "can't be blank"
             }
           ]
  end

  test "invalid params for polymorphic embed (many)" do
    chset =
      DemoReminder.changeset(%{
        text: "",
        channels: [
          %{
            type: "email",
            address: "",
            confirmed: :wrong
          },
          %{
            type: "sms",
            number: ""
          }
        ]
      })

    details = DetailsTransformable.transform(chset)

    assert sort_field_violations(details) == [
             %FieldViolation{
               path: [:channels, 0, :address],
               description: "can't be blank"
             },
             %FieldViolation{
               path: [:channels, 0, :confirmed],
               description: "is invalid"
             },
             %FieldViolation{
               path: [:channels, 1, :number],
               description: "can't be blank"
             },
             %FieldViolation{
               path: [:text],
               description: "can't be blank"
             }
           ]
  end

  defp sort_field_violations(details) do
    Enum.sort_by(details, &{&1.path, &1.description})
  end
end
