PhoenixPubSubPostgres
=====================

This package provides postgres adapater for [Phoenix](http://github.com/phoenixframework/phoenix)'s Pub/Sub channels.


Demo
---
Open pgchat.opendrops.com in two different browsers windows and start sending some messages. The message passing is handled by postgres's built-in [pubsub support] (http://www.postgresql.org/docs/9.1/static/sql-notify.html)

Demo app source
--------------
Source code of the demo app is available at http://github.com/opendrops/pgchat-demo-app

 -
How to use
---------

Add phoenix_pubsub_postgres to your mix deps

    defp deps do
      [{:phoenix, github: "phoenixframework/phoenix", override: true},
       {:phoenix_pubsub_postgres, "~> 0.0.2"},
       {:postgrex, ">= 0.0.0"},
       {:cowboy, "~> 1.0"}]
    end

To use Postgres as your PubSub adapter, simply add it to your Endpoint's config and modify it as needed.

    config :my_app, MyApp.Endpiont,
      ...
      pubsub: [name: MyApp.PubSub,
               adapter: PhoenixPubSubPostgres,
               hostname: "localhost",
               database: "myapp_db_env",
               username: "postgres",
               password: "postgres"]
