require "json"
require "db"
require "log"
require "./*"

# APIParser parses a HTTP request and make CRUD operation
class APIParser
  getter listen_port
  setter db_engine
  getter default_db_engine

  # reads environment variable and connect to db
  def initialize(listen_port : Int32, db_engine : DBEngine)
    @listen_port = listen_port
    @db_engine = db_engine
    @default_db_engine = db_engine
  end

  # find a verb and rest call
  def parse(url, method, body,engine)
    app = find_tag(url, 1)
    case app
    when "object"
      table_name = find_tag(url, 2)
      table_json : JSON::Any
      begin
        table_json = JSON.parse(body.not_nil!.gets_to_end)
      rescue ex
        return {"error" => true, "description" => "table definition is null", "err_id" => 1}.to_json
      end
      engine.create_table(table_name, method, table_json, engine)
    when "luck_db"
      db_name = find_tag(url, 2)
      db_id_json = engine.read(db_name, "Exist", nil, %({"dbname" : "#{db_name}"}))
      db_id : String = ""
      if db_id_json.is_a? JSON::Any
        db_id_json.not_nil!.as_h.each do |k, v|
          db_id = v.to_s
        end
      end
      db_json = engine.read(db_name, "ID", db_id.not_nil!)
      if db_json.is_a? JSON::Any
        db_hash = db_json.not_nil!.as_h
      end
      db_host : String = ""
      db_password : String = ""
      db_engine_name : String = ""
      if db_hash.is_a? Hash
        db_host = db_hash["dbhost"].to_s.not_nil!
        db_password = db_hash["dbpassword"].to_s
        db_engine_name = db_hash["dbenginename"].to_s.not_nil!
      end
      begin
        config = LuckConfig.new(db_host, db_password, db_name, db_engine_name)
        case config.db_engine_name
        when "postgres"
          new_db_engine = DBEnginePostgres.new(config.db_url.not_nil!)
        else
          new_db_engine = DBEngineSqlite3.new(config.db_url.not_nil!)
        end
      rescue ex
        return %({"blalal": "#{ex.message}"}).to_json
      end
      url = url.gsub("luck_db/#{db_name}/", "")
      parse(url,method, body, new_db_engine)
    else
      verb = find_tag(url, 2)
      crud_object(app, verb, method, body, url, engine)
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
  def crud_object(table_name, verb, http_method, http_body, url,engine : DBEngine)
    case http_method
    when "GET"
      result = [] of JSON::Any
      if http_body
        result = engine.read(table_name, verb, find_tag(url, 3), http_body.not_nil!.gets_to_end)
      else
        result = engine.read(table_name, verb, find_tag(url, 3))
      end
      result.to_json
    when "POST"
      engine.insert(table_name, verb, find_tag(url, 3), http_body, engine)
    when "PATCH"
      engine.update(table_name, verb, find_tag(url, 3), http_body, engine)
    when "DELETE"
      engine.delete(table_name, verb, find_tag(url, 3), http_body)
    end
  end

  # Start listening on local network
  def start
    server = HTTP::Server.new() do |c|
      c.response.content_type = "application/json"
      c.response.print parse(c.request.path, c.request.method, c.request.body,@db_engine)
    end
    address = server.bind_tcp @listen_port
    Log.info { "start listening on:" }
    Log.info &.emit("#{address}")
    server.listen
  end
end
