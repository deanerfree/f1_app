# lib/application.ex
defmodule DataRequest.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      # Start the web server
      {Task.Supervisor, name: DataRequest.TaskSupervisor},
      {Plug.Cowboy, scheme: :http, plug: DataRequest.Router, options: [port: 8080]}
    ]

    opts = [strategy: :one_for_one, name: DataRequest.Supervisor]

    Logger.info("Starting server at http://localhost:8080")
    Supervisor.start_link(children, opts)
  end
end
