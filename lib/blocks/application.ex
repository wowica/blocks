defmodule Blocks.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BlocksWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:blocks, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Blocks.PubSub},
      {Finch, name: Blocks.Finch},
      Blocks.BlocksDb,
      {Blocks.ChainSyncClient, url: ogmios_connection_url()},
      BlocksWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Blocks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BlocksWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp ogmios_connection_url() do
    Application.get_env(:blocks, :ogmios_url)
  end
end
