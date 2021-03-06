use Mix.Releases.Config,
    default_release: :neoscan,
    default_environment: Mix.env

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :test
end

environment :prod do
  set include_erts: false
  set include_src: false
  set cookie: :"UHLs;22CbwNqpN?3g9`c|?.>XO;s%]yP0aup<SmL]`.8bAbujy1[%4.23%1Ya"	
end

release :neoscan_sync do
  set version: current_version(:neoscan)
  set commands: [migrate: "rel/commands/migrate.sh", seed: "rel/commands/seed.sh"]
  set applications: [
        :runtime_tools,
        :neoscan,
        neoscan_node: :permanent,
        neoscan_sync: :permanent,
      ]
end

release :neoscan_api do
  set version: current_version(:neoscan)
  set commands: [migrate: "rel/commands/migrate.sh", seed: "rel/commands/seed.sh"]
  set applications: [
        :runtime_tools,
        :neoscan,
        neoscan_cache: :permanent,
        neoscan_node: :permanent,
        neoscan_web: :permanent
      ]
end