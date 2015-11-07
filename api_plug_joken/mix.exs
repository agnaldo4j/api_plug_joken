defmodule ApiPlugJoken.Mixfile do
  use Mix.Project

  def project do
    [app: :api_plug_joken,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :cowboy, :plug, :amnesia],
     mod: {ApiPlugJoken, []}]
  end

  defp deps do
    [{:amnesia, github: "meh/amnesia", branch: "master"},
     {:poison, "~> 1.5.0"},
     {:cowboy, "~> 1.0.0"},
     {:plug, "~> 1.0"},
     {:joken, github: "bryanjos/joken", branch: "master"}]
  end
end
