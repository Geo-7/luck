require "json"
require "sqlite3"
require "db"
require "log"
require "pg"
class APIParser
  @db_host: String =""
  @db_password: String =""
  @db_name: String =""
  @db_engine: String =""
  @listen_port: Int32 = 5700
  @db_url: String ="luckdb"
  @db: DB::Database=DB.open("sqlite3://dummy")
  getter listen_port
  def initialize()
    get_env()
    begin
      @db = DB.open(@db_url)
      Log.info &.emit "Connected to #{@db_engine}"
    rescue exception
      pp exception.message
      abort("Could not connect to DB")
    end
  end
    def parse(url,method,body)
      app = find_tag(url,1)
      case app
      when "object"
        table_name = find_tag(url,2)
        create_table(table_name, method, body)
      when "nothing"
        return "noting"
      else
        obj_value =find_tag(url,2)
        crud_object(app,obj_value, method,body)
      end
    end
    def find_tag(url,segment)
      parts = url.count("/")
      if segment > parts
        return false
      end
      i = 0
      end_offset =0
      start =0
      while i < segment
        start =  url.index("/",end_offset).not_nil! + 1
        if url.index("/",start)
          end_offset = url.index("/",start).not_nil!
        else
          end_offset = url.size 
        end
        i+=1
      end
      url[start..end_offset-1]
    end
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
    def make_create_table_str(table_name,table_json)
      table_str =""
      table_json.as_h.each do |k|
        table_str += ", " + k[0].to_s + " " + k[1].to_s
      end
      case @db_engine
      when "sqlite3"
        str ="CREATE TABLE #{table_name}(id INTEGER PRIMARY KEY#{table_str})"
      when "postgres"
        str ="CREATE TABLE #{table_name}(id SERIAL #{table_str})"
      else
        str=""
      end
      str
    end
    def crud_object(table_name, obj_value, http_method, http_body)
      name =""
      age= ""
      case http_method
      when "GET"
        @db.query "select * from #{table_name}" do |rs|
          rs.each do
            id = rs.read(Int64)
            name =rs.read(String)
            age = rs.read(String)
          end
        end
        return {name: name,age: age}.to_json
      when "POST"
        body = http_body.not_nil!
        o = JSON.parse(body.gets_to_end)
        query = "insert into #{table_name}(name,att) values('#{o["name"]}','#{o["att"]}')"
        result = @db.exec(query)
        return result
      when "PATCH"
        ...
        
      
      when "DELETE"
        ...
        
      end
      
    end
    def get_env()
      begin
        key= "RANDOM1400vat2412armAMDbobomiz44"
        iv="rtyu2000tpk43320"
        @db_name  = ENV.["luck_db_name"] ||= "luck"
        @db_engine  = ENV.["luck_db_engine"] ||= "sqlite3"
        case @db_engine
        when "postgres"
          @db_host = ENV.["luck_db_host"] ||= "127.0.0.1"
          @db_password = ENV.["luck_db_password"]
          @db_password = decrypt Base64.decode(@db_password), key, iv ||= "moreluck"
          @db_url = "postgres://#{@db_password}@#{@db_host}/#{@db_name}"
        when "sqlite3"
          @db_url = "sqlite3://#{@db_name}"
        end
        @listen_port = (ENV.["luck_listen_port"] ||="5800").to_i
      rescue ex
        p ex.message
        abort("DB connection string is not set ENV varibale")
        ex.message
      end
    end
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