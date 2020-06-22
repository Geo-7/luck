# Luck is a headless CMS
require "http/server"
require "log"
require "./luck_func"
module Luck
  VERSION = "0.1.0"
  Log.info {"Program started"}
  api = APIParser.new()
  server = HTTP::Server.new() do |c|
    c.response.content_type="application/json"
    c.response.print api.parse(c.request.path,c.request.method,c.request.body)
  end  
  address =server.bind_tcp 5700
  Log.info &.emit("#{address}")
  Log.info {"start listening on 5700"}
  server.listen
end
