require "json"
require "sqlite3"
require "db"
require "log"
require "pg"
#APIParser parses a HTTP request and make CRUD operation
class APIParser
  @db_host : String = ""
  @db_password : String = ""
  @db_name : String = "luck.db"
  @db_engine : String = ""
  @listen_port : Int32 = 5700
  @db_url : String = ""
  #TODO Fix this stupidity I create this dummy beacuse I can compile the app and because I open the connection in begin rescue 
  # inside initialize method of APIParser 
  @db : DB::Database = DB.open("sqlite3://dummy")
  getter listen_port
  setter db_engine

  #reads environment variable and connect to db
  def initialize
    get_env()
    begin
      @db = DB.open(@db_url)
      Log.info &.emit "Connected to #{@db_engine}"
    rescue exception
      pp exception.message
      abort("Could not connect to DB")
    end
  end
  #find a verb and rest call 
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
  #find HTTP resource request
  def find_tag(url, segment)
    parts = url.count("/")
    if segment > parts
      return false
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
  #creating table in database
  def create_table(table_name, http_method, http_body)
    body = http_body.not_nil!
    table_json = JSON.parse(body.gets_to_end)
    case http_method
    when "POST"
      query = make_create_table_str(table_name, table_json)
      @db.exec(query)
    else
      ...
    end
  end
  #create query for making new table
  def make_create_table_str(table_name, table_json)
    table_str = ""
    table_json.as_h.each do |k|
      table_str += ", " + k[0].to_s + " " + k[1].to_s
    end
    case @db_engine
    when "sqlite3"
      str = "CREATE TABLE #{table_name}(id INTEGER PRIMARY KEY#{table_str})"
    when "postgres"
      str = "CREATE TABLE #{table_name}(id SERIAL#{table_str})"
    else
      str = ""
    end
    str
  end
  #create query string for insert
  def make_insert_str(table_name, table_json)
    value_str = ""
    table_json.as_h.each do |k|
      value_str += "'" + k[1].to_s + "', "
    end
    value_str = value_str[0,(value_str.size - 2)]
    column_str = ""
    table_json.as_h.each do |k|
      column_str += k[0].to_s + ", "
    end
    column_str = column_str[0,(column_str.size - 2)]
    str = "INSERT INTO #{table_name}(#{column_str}) values(#{value_str})"
    str
  end
  #find a HTTP verb
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
      @db.exec make_insert_str(table_name,insert_json)
    when "PATCH"
      update_json = JSON.parse(http_body.not_nil!.gets_to_end)
      @db.exec make_update_str(table_name,update_json)
    when "DELETE"
      delete_json = JSON.parse(http_body.not_nil!.gets_to_end)
      @db.exec "DELETE from #{table_name} where id =#{delete_json["id"].to_s}"
    end
  end
  # make update query string
  def make_update_str(table_name,update_json)
    query ="UPDATE #{table_name} SET "
    update_json.as_h.each do |k,v|
      if k !="id"
        query += "#{k}='#{v}', "
      end
    end
    query = query[0,(query.size-2)]
    query += " WHERE id=#{update_json["id"].to_s}"
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
  #reads environment varibale
  def get_env
    begin
      key = "RANDOM1400vat2412armAMDbobomiz44"
      iv = "rtyu2000tpk43320"
      @db_name = ENV.["luck_db_name"] ||= "luck.db"
      @db_engine = ENV.["luck_db_engine"] ||= "sqlite3"
      case @db_engine
      when "postgres"
        @db_host = ENV.["luck_db_host"] ||= "127.0.0.1"
        @db_password = ENV.["luck_db_password"]
        @db_password = decrypt Base64.decode(@db_password), key, iv ||= "moreluck"
        @db_url = "postgres://#{@db_password}@#{@db_host}/#{@db_name}"
      when "sqlite3"
        @db_url = "sqlite3://#{@db_name}"
      end
      @listen_port = (ENV.["luck_listen_port"] ||= "5800").to_i
    rescue ex
      p ex.message
      abort("DB connection string is not set ENV varibale")
      ex.message
    end
  end
  #decrypt data
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
