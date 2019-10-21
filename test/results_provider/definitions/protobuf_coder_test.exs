defmodule ResultsProvider.Definitions.ProtobufCoderTest do
  use ExUnit.Case

  alias ResultsProvider.Definitions.MatchResult
  alias ResultsProvider.Definitions.PeriodResult
  alias ResultsProvider.Definitions.ProtobufCoder

  test "Consistence on protocol for coding Protobuf messages" do
    match_result = %MatchResult{
      id: 1,
      date: "01/01/2000",
      home_team: "La Coruna",
      away_team: "Eibar",
      ft: %PeriodResult{home_goals: 0, away_goals: 0, result: "H"},
      ht: %PeriodResult{home_goals: 0, away_goals: 0, result: "D"}
    }

    encoded = ProtobufCoder.encode(match_result)
    assert match_result == MatchResult.decode(encoded)
  end

  test "Raise Error if bad argument when coding" do
    assert_raise ArgumentError, fn -> ProtobufCoder.encode("no_valid_arg") end
  end
end
