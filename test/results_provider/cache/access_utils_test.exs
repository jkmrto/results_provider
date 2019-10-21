defmodule ResultsProvider.Cache.AccessUtilsTest do
  alias ResultsProvider.Definitions.Results
  alias ResultsProvider.Definitions.MatchResult
  alias ResultsProvider.Definitions.PeriodResult
  alias ResultsProvider.Cache.AccessUtils
  alias ResultsProvider.Cache.Handler, as: CacheHandler
  use ExUnit.Case

  # ms
  @delay_after_cache_handler_launch 100

  test "Consistence when accessing Resuls from cache" do
    start_supervised!({CacheHandler, [startup_load: true]})
    :timer.sleep(@delay_after_cache_handler_launch)

    {league, season} = {"SP1", "201617"}

    expected_result = %Results{
      league: league,
      season: season,
      results: [
        %MatchResult{
          id: 1,
          date: "01/01/2000",
          home_team: "La Coruna",
          away_team: "Eibar",
          ft: %PeriodResult{home_goals: 0, away_goals: 0, result: "H"},
          ht: %PeriodResult{home_goals: 0, away_goals: 0, result: "D"}
        }
      ]
    }

    assert expected_result == AccessUtils.get_league_and_season_results(league, season)
  end
end
