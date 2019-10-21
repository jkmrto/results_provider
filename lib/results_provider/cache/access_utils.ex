defmodule ResultsProvider.Cache.AccessUtils do
  @moduledoc """
  Functionalities to facilitate the access to the ETS table :results_table
  """
  alias ResultsProvider.Definitions.Results

  @table_name :results_table

  def get_by_league_and_season(league, season) do
    :ets.match_object(@table_name, {{league, season}, :_})
  end

  def get_league_and_season_results(league, season) do
    results = get_by_league_and_season(league, season)

    %Results{
      results: results |> Enum.map(fn {_, x} -> x end),
      league: league,
      season: season
    }
  end
end
