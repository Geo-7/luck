require "sqlite3"

class DBEngineSqlite3 < DBEngine
  getter db : DB::Database

  def initialize(db_url : String)
    db : DB::Database
    begin
      db = DB.open(db_url.not_nil!)
      Log.info &.emit "Connected to SQLite3"
    rescue ex
      Log.info &.emit "#{ex}"
      pp ex.message
      abort("Could not connect to db")
    end
    @db = db.not_nil!
    @db.exec("CREATE TABLE IF NOT EXISTS luck_object(id serial,name varchar,definition json)")
  end

  def read(table_name, verb, id, http_body)
    result_array = [] of DB::Any
    column_names = [] of String
    case verb
    when "false"
      @db.query_all "select * from #{table_name}" do |rs|
        rs = rs.as(SQLite3::ResultSet)
        column_names = rs.column_names
        rs.column_names.each do
          result_array << rs.read
        end
      end
      make_json(result_array,column_names)
    when "ID"
      @db.query_one "SELECT * FROM #{table_name} where id =?",id do |rs|
        rs =rs.as SQLite3::ResultSet
        column_names =rs.column_names
        rs.column_names.each do
          result_array << rs.read
        end
      end
      make_json(result_array,column_names)
    when "Exist"
      str, a = make_filter_str(table_name, JSON.parse(http_body.not_nil!.gets_to_end))
      result = @db.query_one "SELECT id FROM #{table_name} where #{str}", args: a, as: Int64
      result = JSON.parse(%({"id": #{result}}))
    end

    
  end

  def make_json(result_array,column_names)
    result = [] of JSON::Any
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
    if result.size == 1
      result[0]
    else
      result
    end
  end

  def make_filter_str(table_name, table_json : JSON::Any)
    str = ""
    args = [] of String
    table_json.as_h.each do |k, v|
      str += "#{k}=? and "
      args << v.to_s
    end
    str = str[0..(str.size - 6)]
    return {str, args}
  end

  # dummy reflection
  def cast_type(value)
    value = value.to_s
    begin
      value.to_i64
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

  # create query string for insert
  def make_insert_str(table_name, table_json)
    column_str =
      String.build { |s| table_json.as_h.each { |k| s << k[0].to_s; s << ", " } }
    column_str = column_str[0, (column_str.size - 2)]
    value_str =
      String.build { |s| table_json.as_h.each { |k| s << "?, " } }
    value = [] of String
    table_json.as_h.each { |k| value << k[1].to_s }
    value_str = value_str[0, (value_str.size - 2)]
    {"INSERT INTO #{table_name}(#{column_str}) values(#{value_str})", value}
  end

  # make update query string
  def make_update_str(table_name, update_json)
    request = [] of String
    query = "UPDATE #{table_name} SET "
    i = 1
    update_json.as_h.each do |k, v|
      if k != "id"
        query += "#{k}=?, "
        i += 1
        request << v.to_s
      end
    end
    request << update_json["id"].to_s
    query = query[0, (query.size - 2)]
    query += " WHERE id=?"
    {query, request}
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

    {"CREATE TABLE #{make_alphanumeric(table_name)}(id INTEGER PRIMARY KEY#{table_str})", error}
  end

  def delete(table_name, verb, id, http_body)
    delete_json = JSON.parse(http_body.not_nil!.gets_to_end)
    @db.exec "DELETE from #{table_name} where id =?", delete_json["id"].as_i64
  end
end
