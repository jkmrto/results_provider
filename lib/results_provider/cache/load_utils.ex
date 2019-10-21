defmodule ResultsProvider.Cache.LoadUtils do
  alias ResultsProvider.Definitions.MatchResult
  alias ResultsProvider.Definitions.PeriodResult

  def format_to_table([
        id,
        league,
        season,
        date,
        home_team,
        away_team,
        fthg,
        ftag,
        ftr,
        hthg,
        htag,
        htr
      ]) do
    {
      {league, season},
      %MatchResult{
        id: id |> String.to_integer(),
        date: date,
        home_team: home_team,
        away_team: away_team,
        ht: parse_period_result(hthg, htag, htr),
        ft: parse_period_result(fthg, ftag, ftr)
      }
    }
  end

  def parse_period_result(hg, ag, r) do
    %PeriodResult{
      home_goals: hg |> String.to_integer(),
      away_goals: ag |> String.to_integer(),
      result: r
    }
  end
end
