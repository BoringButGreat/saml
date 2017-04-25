import Record

defmodule SAML.Assertion do
  defmodule Subject do
    defstruct [
      name: nil,
      confirmation_method: nil,
      not_on_or_after: nil
    ]

    defrecordp :esaml, :esaml_subject, extract(:esaml_subject, from_lib: "esaml/include/esaml.hrl")

    def from_esaml(esaml() = subject) do
      %__MODULE__{
        name: extract_name(subject),
        confirmation_method: extract_confirmation_method(subject),
        not_on_or_after: extract_not_on_or_after(subject)
      }
    end

    defp extract_name(esaml(name: name)), do: to_string(name)

    defp extract_confirmation_method(esaml(confirmation_method: confirmation_method)) do
      confirmation_method
    end

    defp extract_not_on_or_after(esaml(notonorafter: not_on_or_after)) do
      case NaiveDateTime.from_iso8601(to_string(not_on_or_after)) do
        {:ok, not_on_or_after} -> not_on_or_after
        _ -> not_on_or_after
      end
    end
  end

  defstruct [
    version: nil,
    issue_instant: nil,
    recipient: nil,
    issuer: nil,
    subject: nil,
    conditions: nil,
    attributes: %{}
  ]

  defrecordp :esaml, :esaml_assertion, extract(:esaml_assertion, from_lib: "esaml/include/esaml.hrl")

  def from_esaml(esaml() = assertion) do
    %__MODULE__{
      version: extract_version(assertion),
      issue_instant: extract_issue_instant(assertion),
      recipient: extract_recipient(assertion),
      issuer: extract_issuer(assertion),
      subject: extract_subject(assertion),
      conditions: extract_conditions(assertion),
      attributes: extract_attributes(assertion),
    }
  end

  defp extract_version(esaml(version: version)), do: to_string(version)

  defp extract_issue_instant(esaml(issue_instant: issue_instant)) do
    case NaiveDateTime.from_iso8601(to_string(issue_instant)) do
      {:ok, issue_instant} -> issue_instant
      _ -> to_string(issue_instant)
    end
  end

  defp extract_recipient(esaml(recipient: recipient)), do: to_string(recipient)

  defp extract_issuer(esaml(issuer: issuer)), do: to_string(issuer)

  defp extract_subject(esaml(subject: nil)), do: nil
  defp extract_subject(esaml(subject: subject)), do: __MODULE__.Subject.from_esaml(subject)

  defp extract_conditions(esaml(conditions: conditions)) do
    for {key, value} <- (conditions || []), into: %{} do
      if key in [:not_on_or_after, :not_before] do
        case NaiveDateTime.from_iso8601(to_string(value)) do
          {:ok, value} -> {key, value}
          _ -> {key, to_string(value)}
        end
      else
        {key, to_string(value)}
      end
    end
  end

  defp extract_attributes(esaml(attributes: attributes)) do
    for {key, value} <- (attributes || []),
    into: %{},
    do: {to_string(key), to_string(value)}
  end
end
