defmodule Autoconfex.MixProject do
  use Mix.Project

  @source_url "https://github.com/zacky1972/autoconfex"

  def project do
    [
      app: :autoconfex,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),

      # Dialyzer
      dialyzer: [
        plt_local_path: "priv/plts/project.plt",
        plt_core_path: "priv/plts/core.plt"
      ],

      # Docs
      name: "Autoconfex",
      source_url: @source_url,
      docs: docs(),

      # Package
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Autoconfex: Auto-configuration of NIFs in C for Elixir."
  end

  defp docs do
    [
      main: "Autoconfex",
      extras: ["README.md", "LICENSE"]
    ]
  end

  defp package do
    [
      name: "autoconfex",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
