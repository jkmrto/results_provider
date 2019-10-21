# We need to start :plug dependency since we are running the tests
# on --no-start mode and we need this libarary starte to process the
# http coming requests
Application.ensure_all_started(:plug)

# Let's start the http endpoint
Plug.Cowboy.http(
  ResultsProvider.Web.Endpoint,
  [],
  port: Application.get_env(:results_provider, :web_port)
)

ExUnit.start()
