defmodule ResultsProvider.Cache.LoadUtilsTest do
  use ExUnit.Case

  # Messages Definitions
  alias ResultsProvider.Definitions.MatchResult
  alias ResultsProvider.Definitions.PeriodResult

  alias ResultsProvider.Cache.LoadUtils

  test "Consistence when parsing csv fields" do
    csv_column_values = [
      "1",
      "SP1",
      "201617",
      "01/01/2016",
      "Madrid",
      "Betis",
      "1",
      "1",
      "D",
      "2",
      "3",
      "A"
    ]

    [id, league, season, date, home_team, away_team, fthg, ftag, ftr, hthg, htag, htr] =
      csv_column_values

    expected_result = {
      {league, season},
      %MatchResult{
        id: id |> String.to_integer(),
        date: date,
        home_team: home_team,
        away_team: away_team,
        ht: %PeriodResult{
          home_goals: hthg |> String.to_integer(),
          away_goals: htag |> String.to_integer(),
          result: htr
        },
        ft: %PeriodResult{
          home_goals: fthg |> String.to_integer(),
          away_goals: ftag |> String.to_integer(),
          result: ftr
        }
      }
    }

    assert expected_result == LoadUtils.format_to_table(csv_column_values)
  end
end
