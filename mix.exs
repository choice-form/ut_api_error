defmodule UtApiError.MixProject do
  use Mix.Project

  @version "0.3.0"

  def project do
    [
      app: :ut_api_error,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.3"},
      {:ecto, "~> 3.9", optional: true},
      {:polymorphic_embed, "~> 5.0", optional: true},
      {:open_api_spex, "~> 3.12", optional: true}
    ]
  end
end
