require "./cruder"
require "db"
require "sqlite3"

class CruderSqlite3 < Cruder
  @db : DB::Database

  def initialize(db_url : String)
    @db = DB.open(db_url)
  end

  def read(table_name)
    result = [] of JSON::Any
    result_array = [] of DB::Any
    column_names = [] of String
    @db.query_all "select * from #{table_name}" do |rs|
      rs = rs.as(SQLite3::ResultSet)
      column_names = rs.column_names
      rs.column_names.each do
        result_array << rs.read
      end
    end
    i = 0
    j = 0
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
end
