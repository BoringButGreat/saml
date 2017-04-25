import Record

defmodule SAML.Organization do
  defrecordp :esaml, :esaml_org, extract(:esaml_org, [from_lib: "esaml/include/esaml.hrl"])

  defstruct [
    name: nil,
    display_name: nil,
    url: nil
  ]

  def from_esaml(esaml() = org) do
    %__MODULE__{
      name: extract_name(org),
      display_name: extract_display_name(org),
      url: extract_url(org)
    }
  end

  def to_esaml(%__MODULE__{} = org) do
    esaml(
      name: to_erl(org.name),
      displayname: to_erl(org.display_name),
      url: to_erl(org.url)
    )
  end

  defp to_erl(nil), do: ''
  defp to_erl(bin) when is_binary(bin), do: to_charlist(bin)
  defp to_erl(other), do: other

  defp extract_name(esaml(name: nil)), do: nil
  defp extract_name(esaml(name: name)), do: to_string(name)

  defp extract_display_name(esaml(displayname: nil)), do: nil
  defp extract_display_name(esaml(displayname: display_name)), do: to_string(display_name)

  defp extract_url(esaml(url: nil)), do: nil
  defp extract_url(esaml(url: url)), do: to_string(url)
end
