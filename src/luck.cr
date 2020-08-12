# Luck is a headless CMS
require "http/server"
require "log"
require "./luck_lib"
require "./luck_config"
module Luck
  VERSION = "0.1.0"
  Log.info {"Program started"}
  config = LuckConfig.new
  db_crud = CruderSqlite3.new(config.db_url.not_nil!)
  case config.db_engine
  when "postgres"
    db_crud = CruderPostgres.new(config.db_url.not_nil!)
  end
  api = APIParser.new(config.listen_port,db_crud,config.db_engine)
  api.start()
end