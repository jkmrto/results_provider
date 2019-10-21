defmodule ResultsProvider.TestSupport.Support do
  alias ResultsProvider.Cache.Handler, as: CacheHandler

  # ms
  @delay_after_cache_handler_launch 100

  def order_league_season_pairs(league_season_pairs) do
    league_season_pairs
    |> Enum.sort_by(fn {league, season} -> league <> season end)
  end

  @doc """
  This function launches the GenServer ResultsProvider.Cache.Handler
  since it is not started when the testing begins.
  At the end of the calling test the CacheHandler GenServer will be removed,
  since it has been started with `start_supervised`.
  https://hexdocs.pm/ex_unit/ExUnit.Callbacks.html#start_supervised!/2
  """
  def start_cache_handler(args) do
    ExUnit.Callbacks.start_supervised!({CacheHandler, args})
    :timer.sleep(@delay_after_cache_handler_launch)
  end
end
