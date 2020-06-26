require "json"
require "sqlite3"
require "db"
require "log"
class APIParser  
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
        db = DB.open("sqlite3://./src/object.db")
        db.exec(query)
      else
        ...
      end
    end
    def make_create_table_str(table_name,table_json)
      table_str =""
      table_json.as_h.each do |k|
        table_str += ", " + k[0].to_s + " " + k[1].to_s
      end
      "CREATE TABLE #{table_name}(ID INTEGER PRIMARY KEY#{table_str})"
    end
    def crud_object(table_name, obj_value, http_method, http_body)
      name =""
      age= ""
      db=DB.open("sqlite3://./src/object.db")
      case http_method
      when "GET"
        db.query "select * from #{table_name}" do |rs|
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
        result = db.exec(query)
        return result
      when "PATCH"
        ...
        
      
      when "DELETE"
        ...
        
      end
      
    end
  end