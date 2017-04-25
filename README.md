# SAML

An elixir wrapper for esaml designed for multitenancy.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `saml` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:saml, "~> 0.1.0"}]
    end
    ```

  2. Ensure `saml` is started before your application:

    ```elixir
    def application do
      [applications: [:esaml, :saml]]
    end
    ```

