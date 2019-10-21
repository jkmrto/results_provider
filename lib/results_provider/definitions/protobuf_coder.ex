defprotocol ResultsProvider.Definitions.ProtobufCoder do
  @doc """
  It encodes data to protobuff messages.
  It creates a protocol to allow encode the messages calling
  this module without having to reference the message module directly
  """
  @fallback_to_any true
  def encode(data)
end

defimpl ResultsProvider.Definitions.ProtobufCoder, for: Any do
  @available_messages [
    ResultsProvider.Definitions.PeriodResult,
    ResultsProvider.Definitions.MatchResult,
    ResultsProvider.Definitions.Results
  ]

  def encode(data = %{__struct__: name})
      when name in @available_messages do
    name.encode(data)
  end

  def encode(data),
    do: raise(ArgumentError, "Protocol #{__MODULE__} not implemented for #{inspect(data)}")
end
