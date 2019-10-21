defmodule ResultsProvider.Web.RespUtils do
  @moduledoc """
  This functions module encapsulates some utilities to
  format the responses that will be sent to the client.
  All the function will return with this format
  {http-code, answer, content-type}
  """

  alias ResultsProvider.Cache.AccessUtils, as: CacheAccess
  alias ResultsProvider.Cache.Handler, as: CacheHandler
  alias ResultsProvider.Definitions.ProtobufCoder
  require Logger

  # Content-types
  @content_protobuff "application/protobuf;proto=results"
  @content_json "application/json"
  @content_text "text/plain"

  # Http codes
  @code_success 200
  @code_wrong_format 400
  @code_not_found 404
  @code_unavailable 503

  def league_season_results(query_params, {league, season}) do
    if CacheHandler.results_ready?(),
      do: league_season_results_ready(query_params, {league, season}),
      else: {@code_unavailable, "Service not available", @content_text}
  end

  def league_season_results_ready(%{"format" => "protobuffer"}, {league, season}) do
    {
      @code_success,
      CacheAccess.get_league_and_season_results(league, season) |> ProtobufCoder.encode(),
      @content_protobuff
    }
  end

  def league_season_results_ready(%{"format" => "json"}, {league, season}) do
    {
      @code_success,
      CacheAccess.get_league_and_season_results(league, season) |> Jason.encode!(),
      @content_json
    }
  end

  def league_season_results_ready(%{"format" => other_format}, _league_season) do
    {
      @code_wrong_format,
      "The format specified #{other_format} is not valid, it should be protobuffer or json",
      @content_text
    }
  end

  # By default the format will be json
  def league_season_results_ready(_format, {league, season}) do
    {
      @code_success,
      CacheAccess.get_league_and_season_results(league, season) |> Jason.encode!(),
      @content_json
    }
  end

  def league_season_pairs_list() do
    case CacheHandler.get_league_season_pair_availables() do
      {:not_ready, []} ->
        {@code_unavailable, "Service not available", @content_text}

      {:ready, list} ->
        {@code_success, league_season_pairs_list_ready(list), @content_json}
    end
  end

  def league_season_pairs_list_ready(leagues_season_pairs) do
    %{
      type: "Season and league pairs available",
      data:
        Enum.map(leagues_season_pairs, fn {league, season} ->
          %{league: league, season: season}
        end)
    }
    |> Jason.encode!()
  end

  def not_found() do
    {
      @code_not_found,
      "What are you looking for?",
      @content_text
    }
  end

  def ready() do
    if CacheHandler.results_ready?(),
      do: {@code_success, "Service available", @content_text},
      else: {@code_unavailable, "Service not available", @content_text}
  end
end
