defmodule Noder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, args) do
    # List all child processes to be supervised
    children = [
      Noder.Client,
      Noder.Server
      # Starts a worker by calling: Noder.Worker.start_link(arg)
      # {Noder.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Noder.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
