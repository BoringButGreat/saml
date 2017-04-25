defmodule Saml.Mixfile do
  use Mix.Project

  def project do
    [app: :saml,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
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
      {:esaml, github: "arekinath/esaml", ref: "0fa4b6396d9c9488032f53e6757a3546e89f470b"}
    ]
  end
end
