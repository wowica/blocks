defmodule Explorer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ExplorerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:explorer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Explorer.PubSub},
      {Finch, name: Explorer.Finch},
      {Explorer.ChainSyncClient, url: ogmios_connection_url()},
      ExplorerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Explorer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExplorerWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp ogmios_connection_url() do
    System.fetch_env!("OGMIOS_URL")
  end
end
