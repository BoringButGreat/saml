import Record
alias PublicKeyUtils.{Key, Certificate}
alias SAML.{Organization, Contact}

defmodule SAML.IdentityProvider.Configuration do
  @moduledoc """
  Configuration of an identity provider.

  #### Fields
  - `certificate` Parsed Certificate for `key`, usually self-signed (See PublicKeyUtils.Certificate)
  - `entity_id` SAML Entity ID
  - `consume_url` URL to send requests (used for audience field of SAML Requests)
  - `name_format` (optional) SAML Name format
  - `signed_requests` (default: true) Whether to sign SAML requests
  - `certificates` (required for service providers) Parsed Certificates to trust as being from this IDP
  - `organization` (optional) Organization details to include in metadata.xml
  - `contact` (optional) Technical contact to include in metadata.xml
  """

  defstruct [
    signed_requests: true,
    certificate: nil,
    certificates: [],
    entity_id: nil,
    consume_url: nil,
    name_format: nil,
    contact: nil,
    organization: nil
  ]

  defrecordp :esaml, :esaml_idp_metadata, extract(:esaml_idp_metadata, from_lib: "esaml/include/esaml.hrl")
  defrecordp :xml_text, :xmlText, extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")

  def from_metadata_url(url) do
    with {:ok, metadata} <- fetch_metadata(url),
    do: from_metadata(metadata)
  end

  def from_metadata(xml) do
    with {:ok, xml} <- parse_metadata(xml),
         {:ok, certificates} <- extract_certificates(xml),
         {:ok, idp} <- identity_provider(xml),
    do: %__MODULE__{from_esaml(idp) | certificates: certificates}
  end

  def from_esaml(esaml() = idp) do
    %__MODULE__{
      organization: extract_organization(idp),
      contact: extract_contact(idp),
      name_format: extract_name_format(idp),
      entity_id: extract_entity_id(idp),
      certificate: extract_certificate(idp)
    }
  end

  def to_esaml(%__MODULE__{} = config) do
    esaml(
      org: to_erl(config.organization),
      tech: to_erl(config.contact),
      name_format: to_erl(config.name_format),
      entity_id: to_erl(config.entity_id),
      certificate: to_erl(config.certificate)
    )
  end

  defp to_erl(nil), do: nil
  defp to_erl(%Certificate{certificate: cert}), do: cert
  defp to_erl(%Key{key: key}), do: key
  defp to_erl(%Organization{} = org), do: Organization.to_esaml(org)
  defp to_erl(%Contact{} = contact), do: Contact.to_esaml(contact)
  defp to_erl(bin) when is_binary(bin), do: to_charlist(bin)
  defp to_erl(list) when is_list(list), do: Enum.map(list, &to_erl/1)

  defp extract_organization(esaml(org: nil)), do: nil
  defp extract_organization(esaml(org: organization)) do
    Organization.from_esaml(organization)
  end

  defp extract_contact(esaml(tech: nil)), do: nil
  defp extract_contact(esaml(tech: contact)) do
    Contact.from_esaml(contact)
  end

  defp extract_name_format(esaml(name_format: nil)), do: nil
  defp extract_name_format(esaml(name_format: name_format)), do: to_string(name_format)

  defp extract_entity_id(esaml(entity_id: nil)), do: nil
  defp extract_entity_id(esaml(entity_id: entity_id)), do: to_string(entity_id)

  defp extract_certificate(esaml(certificate: nil)), do: nil
  defp extract_certificate(esaml(certificate: :undefined)), do: nil
  defp extract_certificate(esaml(certificate: certificate)) do
    case Certificate.load(certificate) do
      {:ok, [certificate | _]} -> certificate
      _ -> nil
    end
  end

  defp extract_certificates(metadata) do
    for(
      xml_text(value: text) <- :xmerl_xpath.string(
        '//dsig:X509Certificate/text()',
        metadata,
        namespace: [{'dsig', :"http://www.w3.org/2000/09/xmldsig#"}]
      ),
      text = to_string(text),
      {:ok, cert} = Certificate.load(text),
      do: cert
    )
    |> List.flatten
    |> case do
      [] -> {:error, :no_certificates_in_metadata}
      certificates -> {:ok, certificates}
    end
  end

  defp fetch_metadata("http" <> _ = url) do
    case :httpc.request(:get, {url, []}, [autoredirect: true], []) do
      {:ok, {{_, 200, _}, _, metadata}} -> {:ok, metadata}
      _ -> {:error, :could_not_fetch_metadata}
    end
  end

  defp parse_metadata(metadata) when is_binary(metadata) or is_list(metadata) do
    try do
      metadata
      |> to_charlist
      |> :xmerl_scan.string(namespace_conformant: true, quiet: true)
      |> case do
        {xml, _} -> {:ok, xml}
        _ -> {:error, :invalid_metadata}
      end
    rescue
      _ -> {:error, :invalid_metadata}
    catch
      :exit, _ -> {:error, :invalid_metadata}
    end
  end

  defp identity_provider(metadata) do
    try do
      case :esaml.decode_idp_metadata(metadata) do
        {:ok, _} = result -> result
        _ -> {:error, :invalid_metadata}
      end
    rescue
      _ -> {:error, :invalid_metadata}
    end
  end
end
