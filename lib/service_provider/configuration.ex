import Record
alias PublicKeyUtils.{Key, Certificate}
alias SAML.{Organization, Contact}

defmodule SAML.ServiceProvider.Configuration do
  defrecord :esaml, :esaml_sp, extract(:esaml_sp, from_lib: "esaml/include/esaml.hrl")

  @moduledoc """
  Provides for configuration of a service provider to identity provider integration.

  It is a good idea to have independant SP configuration for each IDP, for maximum flexibility.
  This will allow an application to rotate keys gradually or support export strength cryptography
  without compromising the security of other integrations.

  #### Fields
  - `key` Parsed RSA Private key (See PublicKeyUtils.Key)
  - `certificate` Parsed Certificate for `key`, usually self-signed (See PublicKeyUtils.Certificate)
  - `consume_url` Where assertions will be sent from IDPs
  - `entity_id` Entity ID of service provider (typically a URI where metadata is served)
  - `certificate_chain` (default: []) Parsed Certificate chain for key.
  - `signed_requests` (default: true) SP signs requests
  - `signed_metadata` (default: true) SP signs metadata
  - `signed_envelopes` (default: true) Expects IDP to sign envelopes
  - `signed_assertions` (default: true) Expects IDP to sign assertions
  - `organization` (optional) Organization details to include in metadata.xml
  - `contact` (optional) Technical contact to include in metadata.xml
  """
  defstruct [
    key: nil,
    certificate: nil,
    certificate_chain: [],
    consume_url: nil,
    entity_id: nil,
    signed_requests: true,
    signed_metadata: true,
    signed_envelopes: true,
    signed_assertions: true,
    organization: %Organization{},
    contact: %Contact{}
  ]

  def to_esaml(%__MODULE__{} = config, idp \\ nil) do
    esaml(
      key: to_erl(config.key),
      certificate: to_erl(config.certificate),
      cert_chain: to_erl(config.certificate_chain),
      trusted_fingerprints: fingerprints(idp),
      consume_uri: to_erl(config.consume_url),
      metadata_uri: to_erl(config.entity_id),
      sp_sign_requests: config.signed_requests,
      idp_signs_assertions: config.signed_assertions,
      sp_sign_metadata: config.signed_metadata,
      idp_signs_envelopes: config.signed_envelopes,
      org: to_erl(config.organization),
      tech: to_erl(config.contact)
    )
  end

  defp to_erl(nil), do: :undefined
  defp to_erl(%Certificate{} = cert), do: with {:ok, der} <- Certificate.der(cert), do: der
  defp to_erl(%Key{key: key}), do: key
  defp to_erl(%Organization{} = org), do: Organization.to_esaml(org)
  defp to_erl(%Contact{} = contact), do: Contact.to_esaml(contact)
  defp to_erl(bin) when is_binary(bin), do: to_charlist(bin)
  defp to_erl(list) when is_list(list), do: Enum.map(list, &to_erl/1)

  defp fingerprints(nil), do: []
  defp fingerprints(%{certificate: certificate, certificates: certificates}) do
    fingerprints = Enum.map(certificates, &({:sha, &1.fingerprints[:sha]}))
    case certificate do
      %{fingerprints: fps} -> [{:sha, fps[:sha]} | fingerprints]
      _ -> fingerprints
    end
  end
end
