require "json"
require "db"
require "log"
require "./cruder"
require "./cruder_sqlite3"
require "./cruder_postgres"
require "./luck_config"




# APIParser parses a HTTP request and make CRUD operation
class APIParser
  getter listen_port
  setter db_engine
  setter cruder_engine
  setter db : DB::Database

  # reads environment variable and connect to db
  def initialize(listen_port : Int32, cruder_engine : Cruder, db_engine : String)
    @db_engine = db_engine
    @listen_port = listen_port
    @cruder_engine =cruder_engine
    @db = cruder_engine.db
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
      create_table(table_name, method, table_json)
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

  # creating table in database
  def create_table(table_name, http_method, table_json)
    case http_method
    when "POST"
      query, error = make_create_table_str(table_name, table_json)
      if !error
        @db.exec "INSERT INTO luck_object(name,definition) values($1,$2)", args: [table_name,table_json.to_json]
        @db.exec query
      else
        {"error" => true, "description" => "could not create table", "err_id" => 2}.to_json
      end
    end
  end

  # create query for making new table
  def make_create_table_str(table_name, table_json)
    table_str = ""
    error = false
    table_json.as_h.each { |k| if k[0].to_s.downcase == "id"
      error = true
    end
    table_str = String.build { |s|
      s << table_str; s << ", "; s << make_alphanumeric(k[0].to_s); s << " "; s << k[1].to_s
    } }
    case @db_engine
    when "sqlite3"
      {"CREATE TABLE #{make_alphanumeric(table_name)}(id INTEGER PRIMARY KEY#{table_str})", error}
    when "postgres"
      {"CREATE TABLE #{make_alphanumeric(table_name)}(id SERIAL#{table_str})", error}
    else
      {"", true}
    end
  end

  # This is for safe table and column name it will delete every character except
  # digit,alphabet,underscore,dash
  def make_alphanumeric(name)
    # (name.chars.select! { |x| x.alphanumeric? }).join
    # name.gsub /[^\w\d_-]/, ""
    name.gsub { |c| c.alphanumeric? ? c : nil }
  end

  # create query string for insert
  def make_insert_str(table_name, table_json)
    column_str =
      String.build { |s| table_json.as_h.each { |k| s << k[0].to_s; s << ", " } }
    column_str = column_str[0, (column_str.size - 2)]
    case @db_engine
    when "sqlite3"
      value_str =
        String.build { |s| table_json.as_h.each { |k| s << "?, " } }
    when "postgres"
      value_str =
        String.build { |s| i = 0; table_json.as_h.each { |k| i += 1; s << "$#{i}, " } }
    else
      value_str = ""
    end

    value = [] of String
    table_json.as_h.each { |k| value << k[1].to_s }
    value_str = value_str[0, (value_str.size - 2)]
    {"INSERT INTO #{table_name}(#{column_str}) values(#{value_str})", value}
  end

  # find a HTTP verb
  def crud_object(table_name, verb, http_method, http_body, url)
    case http_method
    when "GET"
      result = [] of JSON::Any
      result = @cruder_engine.read(table_name,verb,find_tag(url, 3),http_body)
      result.to_json
    when "POST"
      insert_json = JSON.parse(http_body.not_nil!.gets_to_end)
      request = make_insert_str(table_name, insert_json)
      @db.exec request[0], args: request[1]
    when "PATCH"
      update_json = JSON.parse(http_body.not_nil!.gets_to_end)
      request = make_update_str(table_name, update_json)
      @db.exec request[0], args: request[1]
    when "DELETE"
      delete_json = JSON.parse(http_body.not_nil!.gets_to_end)
      case @db_engine
      when "sqlite3"
        @db.exec "DELETE from #{table_name} where id =?", delete_json["id"].as_i64
      when "postgres"
        @db.exec "DELETE from #{table_name} where id =$1", delete_json["id"].as_i64
      end
    end
  end

  # make update query string
  def make_update_str(table_name, update_json)
    request = [] of String
    query = "UPDATE #{table_name} SET "
    i = 1
    update_json.as_h.each do |k, v|
      if k != "id"
        case @db_engine
        when "postgres"
          query += "#{k}=$#{i}, "
        else
          query += "#{k}=?, "
        end
        i += 1
        request << v.to_s
      end
    end
    request << update_json["id"].to_s
    query = query[0, (query.size - 2)]
    case @db_engine
    when "postgres"
      query += " WHERE id=$#{i}"
    else
      query += " WHERE id=?"
    end

    {query, request}
  end

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

