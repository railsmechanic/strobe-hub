# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#

# config :logger,
#   backends: [:console, {LoggerFileBackend, :debug_log}]

config :logger, :debug_log,
  path: "log/otis.debug.log",
  level: :debug

config :logger, :console,
  level: :info,
  format: "$date $time $metadata [$level]$levelpad $message\n",
  sync_threshold: 1_000_000,
  metadata: [:module, :line],
  colors: [info: :green]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
config :porcelain, :driver, Porcelain.Driver.Goon
config :porcelain, :goon_driver_path, "#{__DIR__}/../bin/goon_darwin_amd64"

config :otis, Otis.Media,
  root: "#{__DIR__}/../_state/fs",
  at: "/fs"

import_config "#{Mix.env}.exs"
