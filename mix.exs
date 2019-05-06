defmodule Saml.Mixfile do
  use Mix.Project

  def project do
    [
      app: :saml,
      version: "0.1.2",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:public_key_utils, "~> 0.1.1", github: "boringbutgreat/public_key_utils"},
      {:esaml, "~> 3.6"}
    ]
  end
end
