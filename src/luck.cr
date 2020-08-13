# Luck is a headless CMS
require "http/server"
require "log"
require "./luck/*"
module Luck
  VERSION = "0.1.0"
  Log.info {"Program started"}
  config = LuckConfig.new
  db_engine = DBEngineSqlite3.new(config.db_url.not_nil!)
  case config.db_engine_name
  when "postgres"
    db_engine = DBEnginePostgres.new(config.db_url.not_nil!)
  end
  api = APIParser.new(config.listen_port,db_engine)
  api.start()
end