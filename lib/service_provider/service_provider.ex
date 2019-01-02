defmodule SAML.ServiceProvider do
  alias SAML.ServiceProvider.Configuration, as: SP
  alias SAML.IdentityProvider.Configuration, as: IDP
  import :erlang, only: [iolist_to_binary: 1]
  require Logger

  def metadata(%SP{} = config, options \\ []) do
    [
      config
      |> SP.to_esaml()
      |> :esaml_sp.generate_metadata()
    ]
    |> :xmerl.export(:xmerl_xml)
    |> format_xml(options)
  end

  def request(%SP{} = config, %IDP{} = idp, options \\ []) do
    [
      :esaml_sp.generate_authn_request(
        idp.consume_url,
        SP.to_esaml(config, idp)
      )
    ]
    |> :xmerl.export(:xmerl_xml)
    |> format_xml(options)
  end

  def validate_assertion(nil, _, _), do: {:error, :no_response}

  def validate_assertion(assertion, %SP{} = config, %IDP{} = idp) do
    sp = SP.to_esaml(config, idp)

    case Base.decode64(assertion) do
      {:ok, rawxml} ->
        {xml, _} = :xmerl_scan.string(to_charlist(rawxml), namespace_conformant: true)

        case :esaml_sp.validate_assertion(xml, sp) do
          {:ok, assertion} ->
            {:ok, SAML.Assertion.from_esaml(assertion)}

          error ->
            Logger.warn("Invalid SAML Assertion (#{config.entity_id}): #{inspect(error)}")
            {:error, :invalid_saml_assertion}
        end

      _ ->
        {:error, :response_unparsable}
    end
  end

  defp format_xml(xml, options) do
    case Keyword.get(options, :format, :iolist) do
      :iolist -> xml
      :string -> xml |> iolist_to_binary
      :base64 -> xml |> iolist_to_binary |> Base.encode64()
      :uri -> xml |> iolist_to_binary |> Base.encode64() |> URI.encode_www_form()
    end
  end
end
