defmodule Valspec.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/mtanca/valspec"

  def project do
    [
      app: :valspec,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "A simple elixir library for Phoenix that combines Swagger documentation and parameter validation.",
      source_url: @source_url,
      package: package()
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
      {:m_goal, "~> 1.2.2"},
      {:open_api_spex, "~> 3.21"}
    ]
  end

  defp package do
    [
      maintainers: ["Mark T"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
