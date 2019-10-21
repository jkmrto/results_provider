use Mix.Config

config :results_provider,
  web_port: 4000,
  results_file: "data/Data.csv",
  startup_load: true

# Application.get_env(:results_provider, :web_port)
