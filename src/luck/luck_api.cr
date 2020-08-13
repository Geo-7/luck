require "json"
require "db"
require "log"


# APIParser parses a HTTP request and make CRUD operation
class APIParser
  getter listen_port
  setter db_engine

  # reads environment variable and connect to db
  def initialize(listen_port : Int32, db_engine : DBEngine)
    @listen_port = listen_port
    @db_engine =db_engine
  end

  # find a verb and rest call
  def parse(url, method, body)
    app = find_tag(url, 1)
    case app
    when "object"
      table_name = find_tag(url, 2)
      table_json : JSON::Any
      begin
        table_json = JSON.parse(body.not_nil!.gets_to_end)
      rescue
        return {"error" => true, "description" => "table definition is null", "err_id" => 1}.to_json
      end
      @db_engine.create_table(table_name, method, table_json,@db_engine)
    when "nothing"
      return "noting"
    else
      verb = find_tag(url, 2)
      crud_object(app, verb, method, body, url)
    end
  end

  # find HTTP resource request
  def find_tag(url, segment)
    parts = url.count("/")
    # TODO should fix this
    if segment > parts
      return "false"
    end
    i = 0
    end_offset = 0
    start = 0
    while i < segment
      start = url.index("/", end_offset).not_nil! + 1
      if url.index("/", start)
        end_offset = url.index("/", start).not_nil!
      else
        end_offset = url.size
      end
      i += 1
    end
    url[start..end_offset - 1]
  end

  # find a HTTP verb
  def crud_object(table_name, verb, http_method, http_body, url)
    case http_method
    when "GET"
      result = [] of JSON::Any
      result = @db_engine.read(table_name,verb,find_tag(url, 3),http_body)
      result.to_json
    when "POST"
      @db_engine.insert(table_name, verb, find_tag(url, 3), http_body,@db_engine)
    when "PATCH"
      @db_engine.update(table_name, verb, find_tag(url, 3), http_body,@db_engine)
    when "DELETE"
      @db_engine.delete(table_name, verb, find_tag(url, 3), http_body)
    end
  end

  # Start listening on local network
  def start
    server = HTTP::Server.new() do |c|
      c.response.content_type = "application/json"
      c.response.print parse(c.request.path, c.request.method, c.request.body)
    end
    address = server.bind_tcp @listen_port
    Log.info { "start listening on:" }
    Log.info &.emit("#{address}")
    server.listen
  end
end

