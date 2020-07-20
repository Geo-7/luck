# Luck is a headless CMS
require "http/server"
require "log"
require "./luck_func"
module Luck
  VERSION = "0.1.0"
  Log.info {"Program started"}
  api = APIParser.new(*LuckConfig.get_env)
  api.start()
end

