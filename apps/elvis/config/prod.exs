use Mix.Config

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
# You should also configure the url host to something
# meaningful, we use this information when generating URLs.
#
# Finally, we also include the path to a manifest
# containing the digested version of static files. This
# manifest is generated by the mix phoenix.digest task
# which you typically run after static files are built.
config :elvis, Elvis.Endpoint,
  server: true,
  # http: [port: {:system, "PORT"}],
  http: [port: 4000],
  # url: [host: "192.168.1.67", port: 4000],
  check_origin: false,
  cache_static_manifest: "priv/static/manifest.json"

papertrail_host = System.get_env("PAPERTRAIL_SYSTEM_HOST")
papertrail_system_name = System.get_env |> Map.get("PAPERTRAIL_SYSTEM_NAME", "unknown")

IO.puts "===> Logging to papertrail: #{papertrail_host}/#{papertrail_system_name}"

config :logger,
  backends: [:console, LoggerPapertrailBackend.Logger],
  level: :info

config :logger, :logger_papertrail_backend,
  host:  papertrail_host,
  system_name: papertrail_system_name,
  level: :debug,
  format: "$date $time $metadata [$level]$levelpad $message\n",
  metadata: [:module, :line]

# Do not print debug messages in production
# config :logger, level: :info

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :elvis, Elvis.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :elvis, Elvis.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
