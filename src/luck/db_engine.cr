abstract class DBEngine
  abstract def read(table_name, verb, id, http_body)

  def insert(table_name, verb, id, http_body, cr)
    begin
      insert_json = JSON.parse(http_body.not_nil!.gets_to_end)
      request = cr.make_insert_str(table_name, insert_json)
      cr.db.exec request[0], args: request[1]
    rescue ex
      {"error" => true, "description" => "#{ex.message}", "err_id" => 3}.to_json 
    end
  end

  def update(table_name, verb, id, http_body, cr)
    update_json = JSON.parse(http_body.not_nil!.gets_to_end)
    request = cr.make_update_str(table_name, update_json)
    cr.db.exec request[0], args: request[1]
  end

  # creating table in database
  def create_table(table_name, http_method, table_json, cr)
    case http_method
    when "POST"
      query, error = make_create_table_str(table_name, table_json)
      if !error
        cr.db.exec "INSERT INTO luck_object(name,definition) values($1,$2)", args: [table_name, table_json.to_json]
        cr.db.exec query
      else
        {"error" => true, "description" => "could not create table", "err_id" => 2}.to_json
      end
    end
  end

  # This is for safe table and column name it will delete every character except
  # digit,alphabet,underscore,dash
  def make_alphanumeric(name)
    # (name.chars.select! { |x| x.alphanumeric? }).join
    # name.gsub /[^\w\d_-]/, ""
    name.gsub { |c| c.alphanumeric? ? c : nil }
  end
end
