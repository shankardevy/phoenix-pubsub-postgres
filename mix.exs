defmodule PhoenixPubSubPostgres.Mixfile do
  use Mix.Project

  def project do
    [app: :phoenix_pubsub_postgres,
     version: "0.0.2",
     description: "Postgresql PubSub adapter for Phoenix apps",
     package: {
     contributors: ["Shankar Dhanasekaran - (shankardevy)"],
       licenses: ["MIT"],
       links: %{"demo" => "http://pgchat.opendrops.com", "github" => "https://github.com/opendrops/phoenix-pubsub-postgres"}  
     }
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :postgrex, :poolboy]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:phoenix, github: "phoenixframework/phoenix", override: true},
     {:postgrex, ">= 0.0.0"},
     {:poolboy, "~> 1.4.2"}]
  end
end
