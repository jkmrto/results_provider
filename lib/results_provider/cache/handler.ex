defmodule ResultsProvider.Cache.Handler do
  @moduledoc """
  It is a GenServer that will be in charge of creating the ETS table  (:results_table) at start up
  and loading the data from the csv file specified at configuration.
  It provides a list with season-leage pairs that area availabe at the cache of Results
  It provides if the results are ready or not (Based on if the results have already been loaded at ETS table )

  """
  alias ResultsProvider.Cache.LoadUtils
  use GenServer
  require Logger

  NimbleCSV.define(MyParser, separator: ",", escape: "\"")

  @data_file Application.get_env(:results_provider, :results_file)
  @table_name :results_table

  # API
  def start_link(args),
    do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def results_ready?(),
    do: GenServer.call(__MODULE__, :results_ready)

  def get_league_season_pair_availables(),
    do: GenServer.call(__MODULE__, :leagues_seasons_available)

  #############
  # Callbacks #
  #############

  def init(startup_load: startup_load) do
    # The table will be linked to this process
    :ets.new(@table_name, table_opts())
    # Load results on cache asynchronously to avoid block rest of the sytem initialization
    if startup_load, do: Process.send(__MODULE__, :load_csv, [])
    {:ok, %{results_ready: false, leagues_seasons_available: []}}
  end

  def handle_call(:results_ready, _from, state = %{results_ready: results_ready}),
    do: {:reply, results_ready, state}

  def handle_call(:leagues_seasons_available, _from, state = %{results_ready: false}),
    do: {:reply, {:not_ready, []}, state}

  def handle_call(
        :leagues_seasons_available,
        _from,
        state = %{results_ready: true, leagues_seasons_available: leagues_seasons_available}
      ),
      do: {:reply, {:ready, leagues_seasons_available}, state}

  def handle_info(:load_csv, _state) do
    {:ok, leagues_seasons_available} = load_csv()

    {:noreply,
     %{
       results_ready: true,
       leagues_seasons_available: leagues_seasons_available
     }}
  end

  def handle_info(msg, state) do
    Logger.warn("#{__MODULE__} Unexpected msg: #{inspect(msg)}")
    {:noreply, state}
  end

  #############
  # Functions #
  #############

  def table_opts() do
    [
      :bag,
      :named_table,
      :public,
      {:read_concurrency, true},
      {:write_concurrency, false}
    ]
  end

  def load_csv() do
    leagues_seasons_available =
      @data_file
      |> File.stream!()
      |> MyParser.parse_stream()
      |> Stream.map(&LoadUtils.format_to_table/1)
      |> Enum.reduce([], fn {league_season, data}, acc ->
        :ets.insert(:results_table, {league_season, data})
        if league_season in acc, do: acc, else: [league_season | acc]
      end)

    {:ok, leagues_seasons_available}
  end
end
