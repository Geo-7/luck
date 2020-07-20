require "json"
require "sqlite3"
require "db"
require "log"
require "pg"

module LuckConfig
  extend self
  getter listen_port
  setter db_engine

  def get_db_connection
  end

  # reads environment varibale
  def get_env
    db = DB::Database
    begin
      key = "RANDOM1400vat2412armAMDbobomiz44"
      iv = "rtyu2000tpk43320"
      db_name = ENV.["luck_db_name"] ||= "luck.db"
      db_engine = ENV.["luck_db_engine"] ||= "sqlite3"
      case db_engine
      when "postgres"
        db_host = ENV.["luck_db_host"] ||= "127.0.0.1"
        db_password = ENV.["luck_db_password"]
        db_password = decrypt Base64.decode(db_password), key, iv ||= "moreluck"
        db_url = "postgres://#{db_password}@#{db_host}/#{db_name}"
      when "sqlite3"
        db_url = "sqlite3://#{db_name}"
      else
        ...
      end
      listen_port = (ENV.["luck_listen_port"] ||= "5800").to_i
    rescue ex
      p ex.message
      abort("DB connection string is not set ENV varibale")
      ex.message
    end
    begin
      db = DB.open(db_url.not_nil!)
      Log.info &.emit "Connected to #{db_engine}"
    rescue
      abort("Could not connect to db")
    end
    {db.not_nil!, db_engine.not_nil!, listen_port.not_nil!}
  end

  # decrypt data
  def decrypt(data, key, iv)
    decipher = OpenSSL::Cipher.new "aes-256-cbc"
    decipher.decrypt
    decipher.key = key
    decipher.iv = iv
    dec_data = IO::Memory.new
    dec_data.write decipher.update(data)
    dec_data.write decipher.final
    dec_data.to_s
  end
end

# APIParser parses a HTTP request and make CRUD operation
class APIParser
  getter listen_port
  setter db_engine

  # reads environment variable and connect to db
  def initialize(db : DB::Database, db_engine : String, listen_port : Int32)
    @db_engine = db_engine
    @listen_port = listen_port
    @db = db
  end

  # find a verb and rest call
  def parse(url, method, body)
    app = find_tag(url, 1)
    case app
    when "object"
      table_name = find_tag(url, 2)
      create_table(table_name, method, body)
    when "nothing"
      return "noting"
    else
      obj_value = find_tag(url, 2)
      crud_object(app, obj_value, method, body)
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
  def create_table(table_name, http_method, http_body)
    body = http_body.not_nil!
    table_json = JSON.parse(body.gets_to_end)
    case http_method
    when "POST"
      query, error = make_create_table_str(table_name, table_json)
      if !error
        @db.exec(query)
      else
        {"error": true, "description": "could not create table"}.to_json
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

  # This is for safe table and column name it will delete every character except digit,alphabet,underscore,dash
  def make_alphanumeric(name)
    # (name.chars.select! { |x| x.alphanumeric? }).join
    # name.gsub /[^\w\d_-]/, ""
    name.gsub { |c| c.alphanumeric? ? c : nil }
  end

  # create query string for insert
  def make_insert_str(table_name, table_json)
    column_str = String.build { |s| table_json.as_h.each { |k| s << k[0].to_s; s << ", " } }
    column_str = column_str[0, (column_str.size - 2)]
    case @db_engine
    when "sqlite3"
      value_str = String.build { |s| table_json.as_h.each { |k| s << "?, " } }
    when "postgres"
      value_str = String.build { |s| i = 0; table_json.as_h.each { |k| i += 1; s << "$#{i}, " } }
    else
      value_str = ""
    end

    value = [] of String
    table_json.as_h.each { |k| value << k[1].to_s }
    value_str = value_str[0, (value_str.size - 2)]
    {"INSERT INTO #{table_name}(#{column_str}) values(#{value_str})", value}
  end

  # find a HTTP verb
  def crud_object(table_name, obj_value, http_method, http_body)
    case http_method
    when "GET"
      # result_array = [] of DB::Any
      # TODO I should fix a type of result_array
      result_array = [] of (Array(PG::BoolArray) | Array(PG::CharArray) | Array(PG::Float32Array) | Array(PG::Float64Array) | Array(PG::Int16Array) | Array(PG::Int32Array) | Array(PG::Int64Array) | Array(PG::NumericArray) | Array(PG::StringArray) | Array(PG::TimeArray) | Bool | Char | Float32 | Float64 | Int16 | Int32 | Int64 | JSON::Any | PG::Geo::Box | PG::Geo::Circle | PG::Geo::Line | PG::Geo::LineSegment | PG::Geo::Path | PG::Geo::Point | PG::Geo::Polygon | PG::Numeric | Slice(UInt8) | String | Time | UInt32 | Nil)
      column_names = [] of String
      @db.query_all "select * from #{table_name}" do |rs|
        column_names = rs.column_names
        rs.column_names.each do
          result_array << rs.read
        end
      end
      i = 0
      j = 0
      result = [] of JSON::Any
      (result_array.size/column_names.size).to_i32.times do
        result_json = JSON.build do |json|
          json.object do
            column_names.size.times do
              json.field column_names[i], cast_type(result_array[j])
              i += 1
              j += 1
            end
          end
        end
        i = 0
        result << (JSON.parse(result_json))
      end
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
        when "sqlite3"
          query += "#{k}=?, "
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
    when "sqlite3"
      query += " WHERE id=?"
    when "postgres"
      query += " WHERE id=$#{i}"
    else
      query += " WHERE id=?"
    end

    {query, request}
  end

  # dummy reflection
  def cast_type(value)
    value = value.to_s
    begin
      value.to_f64
    rescue exception
      case value
      when "false"
        false
      when "true"
        true
      else
        value
      end
    end
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
