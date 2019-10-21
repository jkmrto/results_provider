defmodule ResultsProvider.Cache.HandlerTest do
  use ExUnit.Case

  # Messages Definitions
  alias ResultsProvider.Definitions.MatchResult
  alias ResultsProvider.Definitions.PeriodResult

  alias ResultsProvider.Cache.Handler, as: CacheHandler
  alias ResultsProvider.Cache.AccessUtils
  alias ResultsProvider.TestSupport.Support

  test "Consistence loading csv data (first data/test_data.csv entry)" do
    Support.start_cache_handler(startup_load: true)

    expected_result = %MatchResult{
      id: 1,
      date: "01/01/2000",
      home_team: "La Coruna",
      away_team: "Eibar",
      ft: %PeriodResult{home_goals: 0, away_goals: 0, result: "H"},
      ht: %PeriodResult{home_goals: 0, away_goals: 0, result: "D"}
    }

    {league, season} = {"SP1", "201617"}
    [{{^league, ^season}, result}] = AccessUtils.get_by_league_and_season(league, season)
    assert expected_result == result
  end

  test "Consistence on league and season pairs available" do
    Support.start_cache_handler(startup_load: true)

    expected_league_season_pairs =
      [
        {"SP1", "201617"},
        {"SP2", "201516"},
        {"SP3", "201617"}
      ]
      |> Support.order_league_season_pairs()

    # Ordering by the same logic that the expected list to avoid misordering issues
    {:ready, legues_season_pairs} = CacheHandler.get_league_season_pair_availables()
    league_season_pairs_available = legues_season_pairs |> Support.order_league_season_pairs()

    assert expected_league_season_pairs == league_season_pairs_available
  end
end
