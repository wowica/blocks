# Blocks

A simple Cardano Blockchain explorer written in [Phoenix LiveView](https://www.phoenixframework.org/) and using [Xogmios](https://github.com/wowica/xogmios).

## Running the application

  * Clone this repository
  * Run `npm install --prefix assets` to install the dependencies for the frontend
  * Run `mix setup` to install dependencies and build the application
  * Populate the `OGMIOS_URL` environment variable - if you don't have one, you can use a managed instance from [Demeter.run](https://demeter.run)
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Running in Docker

A Docker compose file is available to allow running the application using the following command:

```
OGMIOS_URL="..." docker-compose up
```