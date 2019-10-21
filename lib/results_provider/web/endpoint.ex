defmodule ResultsProvider.Web.Endpoint do
  @moduledoc """
  This module will receive the http requests through the Plug Cowboy.
  It will match against all the possible url, If no one matches
  the last method of not found will me launched.
  """
  use Plug.Router
  alias ResultsProvider.Web.RespUtils
  require Logger

  @site_entrypoint "/results-provider"

  # Using Plug.Logger for logging request information
  plug(Plug.Logger)
  # responsible for matching routes
  plug(:match)
  # responsible for dispatching responses
  plug(:dispatch)

  ### Endpoints

  get @site_entrypoint <> "/ready" do
    {code, answer, content_type} = RespUtils.ready()
    send_resp_with_content_type(conn, code, answer, content_type)
  end

  get @site_entrypoint <> "/list" do
    {code, answer, content_type} = RespUtils.league_season_pairs_list()
    send_resp_with_content_type(conn, code, answer, content_type)
  end

  get @site_entrypoint <> "/:league/:season" do
    conn = fetch_query_params(conn)

    {code, answer, content_type} =
      RespUtils.league_season_results(
        conn.query_params,
        {league, season}
      )

    send_resp_with_content_type(conn, code, answer, content_type)
  end

  match _ do
    {code, answer, content_type} = RespUtils.not_found()
    send_resp_with_content_type(conn, code, answer, content_type)
  end

  defp send_resp_with_content_type(conn, code, answer, content_type) do
    conn
    |> Plug.Conn.put_resp_header("content-type", content_type)
    |> send_resp(code, answer)
  end
end
