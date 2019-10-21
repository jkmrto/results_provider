defmodule ResultsProvider.Web.EndpointTest do
  use ExUnit.Case
  use Plug.Test

  alias ResultsProvider.Web.Endpoint
  alias ResultsProvider.TestSupport.Support
  alias ResultsProvider.Definitions.{Results, MatchResult, PeriodResult}

  @site_entrypoint "/results-provider"

  # Http codes
  @code_success 200
  @code_wrong_format 400
  @code_not_found 404
  @code_unavailable 503

  test "Service is ready if the the data has been loaded" do
    Support.start_cache_handler(startup_load: true)
    conn = do_request(:get, @site_entrypoint <> "/ready")
    assert conn.status == @code_success
  end

  test "Consistence on available league-season pairs" do
    Support.start_cache_handler(startup_load: true)

    expected_league_season_pairs =
      [
        {"SP1", "201617"},
        {"SP2", "201516"},
        {"SP3", "201617"}
      ]
      |> Support.order_league_season_pairs()

    conn = do_request(:get, @site_entrypoint <> "/list")

    {:ok, %{"data" => data, "type" => "Season and league pairs available"}} =
      conn.resp_body |> Jason.decode()

    league_season_pairs =
      data
      |> Enum.map(fn %{"league" => league, "season" => season} -> {league, season} end)
      |> Support.order_league_season_pairs()

    assert league_season_pairs == expected_league_season_pairs
  end

  test "Consistence on Results with Protobuffer format (/SP1/201617?format=protobuffer)" do
    Support.start_cache_handler(startup_load: true)

    expected_result = %Results{
      league: "SP1",
      season: "201617",
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

    conn = do_request(:get, @site_entrypoint <> "/SP1/201617?format=protobuffer")
    resp_body_decoded = conn.resp_body |> Results.decode()
    assert expected_result == resp_body_decoded
  end

  test "Consistence on Results with json format (/SP1/201617?format=json)" do
    Support.start_cache_handler(startup_load: true)

    expected_result = %{
      league: "SP1",
      season: "201617",
      results: [
        %{
          id: 1,
          date: "01/01/2000",
          home_team: "La Coruna",
          away_team: "Eibar",
          ft: %{home_goals: 0, away_goals: 0, result: "H"},
          ht: %{home_goals: 0, away_goals: 0, result: "D"}
        }
      ]
    }

    conn = do_request(:get, @site_entrypoint <> "/SP1/201617?format=json")

    resp_body_decoded = conn.resp_body |> Jason.decode!(keys: :atoms)
    assert expected_result == resp_body_decoded
  end

  test "No format specification on Results request means json response (/SP1/201617)" do
    Support.start_cache_handler(startup_load: true)

    expected_result = %{
      league: "SP1",
      season: "201617",
      results: [
        %{
          id: 1,
          date: "01/01/2000",
          home_team: "La Coruna",
          away_team: "Eibar",
          ft: %{home_goals: 0, away_goals: 0, result: "H"},
          ht: %{home_goals: 0, away_goals: 0, result: "D"}
        }
      ]
    }

    conn = do_request(:get, @site_entrypoint <> "/SP1/201617")

    resp_body_decoded = conn.resp_body |> Jason.decode!(keys: :atoms)
    assert expected_result == resp_body_decoded
  end

  test "400 Error when format is not valid" do
    Support.start_cache_handler(startup_load: true)
    conn = do_request(:get, @site_entrypoint <> "/SP1/201617?format=wrong_format")
    assert conn.status == @code_wrong_format
  end

  test "Service is not availalbe if data is not loaded (/ready request)" do
    Support.start_cache_handler(startup_load: false)
    conn = do_request(:get, @site_entrypoint <> "/ready")
    assert conn.status == @code_unavailable
  end

  test "Service is not availalbe if data is not loaded (/list request)" do
    Support.start_cache_handler(startup_load: false)
    conn = do_request(:get, @site_entrypoint <> "/list")
    assert conn.status == @code_unavailable
  end

  test "Service is not availalbe if data is not loaded (/league/season request)" do
    Support.start_cache_handler(startup_load: false)
    conn = do_request(:get, @site_entrypoint <> "/SP1/201617")
    assert conn.status == @code_unavailable
  end

  test "Not found code when requesting not supported path (random place)" do
    Support.start_cache_handler(startup_load: true)
    conn = do_request(:get, @site_entrypoint <> "/random_place")
    assert conn.status == @code_not_found
  end

  # :: conn
  defp do_request(method, url) do
    conn(:get, url)
    |> Endpoint.call([])
  end
end
