# Blocks

A simple Cardano Blockchain explorer written in [Phoenix LiveView](https://www.phoenixframework.org/) and using [Xogmios](https://github.com/wowica/xogmios).

  * Run `mix setup` to install and setup dependencies
  * Populate the `OGMIOS_URL` environment variable with the access url for [Ogmios](https://ogmios.dev/).
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Running in Docker

A Docker compose file is available to allow running the application using the following command:

```
OGMIOS_URL="..." docker-compose up
```