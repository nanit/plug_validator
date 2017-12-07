defmodule PlugValidator.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plug_validator,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      description: "Validates incoming parameters in router context",
      package: package(),
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
      {:plug, "~> 1.0"},
      {:poison, "~> 3.1", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    [ name: :plug_validator,
      files: ["lib", "mix.exs"],
      maintainers: ["Erez Rabih"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/nanit/plug_validator"}]
  end
end
