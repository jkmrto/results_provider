defmodule ResultsProvider do
  @moduledoc """
  THis module will start the applications.
  It will run two childs
  * A Plug.Cowboy listener to receive Http requests and forward them to ResultsProvider.Web.Endpoint
  * A ResultsProvider.Cache.Handler that will create the ETS table to store matches
  results and will read the data from the csv saving it to the ETS table.
  """
  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Use Plug.Cowboy.child_spec/3 to register our endpoint as a plug
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: ResultsProvider.Web.Endpoint,
        options: [port: Application.get_env(:results_provider, :web_port)]
      ),
      {ResultsProvider.Cache.Handler,
       [startup_load: Application.get_env(:results_provider, :startup_load)]}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end
end
