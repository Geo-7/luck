require "pg"
require "./cruder"

class CruderPostgres < Cruder
    getter db : DB::Database
    def initialize(db_url : String)
      db : DB::Database
        begin
          db = DB.open(db_url.not_nil!)
          Log.info &.emit "Connected to PostgreSQL"
        rescue ex
          Log.info &.emit "#{ex}"
          abort("Could not connect to db")
        end
        @db = db.not_nil!
        @db.exec("CREATE TABLE IF NOT EXISTS luck_object(id serial,name varchar,definition json)")
    end
    def read(table_name,verb,id,http_body)
        result = [] of JSON::Any
        case verb
        when "false"
          result = @db.query_all "select row_to_json(#{table_name}) from #{table_name}", as: JSON::Any
        when "ID"
          result = @db.query_one "SELECT row_to_json(#{table_name}) from #{table_name} where id =$1", id, as: JSON::Any
        when "Exist"
          str, a = make_filter_str(table_name, JSON.parse(http_body.not_nil!.gets_to_end))
          result = @db.query_one "SELECT id FROM #{table_name} where #{str}", args: a, as: Int32
          result = JSON.parse(%({"id": #{result}}))
        end
    end
    def make_filter_str(table_name, table_json : JSON::Any)
        i = 1
        str = ""
        args = [] of String
        table_json.as_h.each do |k, v|
          str += "#{k}=$#{i} and "
          args << v.to_s
          i += 1
        end
        str = str[0..(str.size - 6)]
        return {str, args}
      end

end