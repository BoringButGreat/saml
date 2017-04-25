import Record

defmodule SAML.Contact do
  defrecordp :esaml, :esaml_contact, extract(:esaml_contact, [from_lib: "esaml/include/esaml.hrl"])

  defstruct [
    name: nil,
    email: nil
  ]

  def from_esaml(esaml() = contact) do
    %__MODULE__{
      name: extract_name(contact),
      email: extract_email(contact)
    }
  end

  def to_esaml(%__MODULE__{} = contact) do
    esaml(
      name: to_erl(contact.name),
      email: to_erl(contact.email)
    )
  end

  defp to_erl(nil), do: ''
  defp to_erl(bin) when is_binary(bin), do: to_charlist(bin)
  defp to_erl(other), do: other

  defp extract_name(esaml(name: nil)), do: nil
  defp extract_name(esaml(name: name)), do: to_string(name)

  defp extract_email(esaml(email: nil)), do: nil
  defp extract_email(esaml(email: email)), do: to_string(email)
end
