defmodule ResultsProvider.Definitions do
  @moduledoc """
  It reads the message definitions at ./protobufs.
  It generates one module associated to each message.
  """
  use Protobuf, from: Path.wildcard("protobufs/*.proto")
end

defmodule ResultsProvider.Definitions.Jason do
  @moduledoc """
  Allow to Jason enconde the structure defined at the module above.
  Look at this repository https://github.com/michalmuskala/jason at bottom of readme.md.
  """
  require Protocol
  Protocol.derive(Jason.Encoder, ResultsProvider.Definitions.PeriodResult)
  Protocol.derive(Jason.Encoder, ResultsProvider.Definitions.MatchResult)
  Protocol.derive(Jason.Encoder, ResultsProvider.Definitions.Results)
end
