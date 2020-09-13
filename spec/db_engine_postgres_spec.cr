require "pg"

def do_test(url : String,db_crud,table_name,luck_header)
  
  describe "POST /object/table_name" do
    it "POST a table json and make a table" do
      data = %({"name": "varchar", "genre": "varchar"})
      response = HTTP::Client.post("#{url}object/#{table_name}", luck_header, data)
      response.body.should eq "DB::ExecResult(@rows_affected=0, @last_insert_id=0)"
    end
  end
  describe "POST /table_name" do
    it "Insert data to a table with a POST" do
      data = %({"name": "her", "genre": "Romance"})
      response = HTTP::Client.post("#{url}#{table_name}", luck_header, data)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
    end
    it "checks if data inserted correctly" do
      response = HTTP::Client.get("#{url}#{table_name}", luck_header)
      response.body.should eq %([{"id":1,"name":"her","genre":"Romance"}])
    end
  end
  describe "POST /table_name" do
    it "Insert data to a table with a POST" do
      data = %({"name": "her", "genre": "Romance"})
      response = HTTP::Client.post("#{url}#{table_name}", luck_header, data)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
    end
    it "checks if data inserted correctly" do
      response = HTTP::Client.get("#{url}#{table_name}", luck_header)
      response.body.should eq %([{"id":1,"name":"her","genre":"Romance"},{"id":2,"name":"her","genre":"Romance"}])
    end
    it "checks if data inserted correctly" do
      response = HTTP::Client.get("#{url}#{table_name}/ID/1", luck_header)
      response.body.should eq %({"id":1,"name":"her","genre":"Romance"})
    end
    it "checks if data inserted correctly" do
      response = HTTP::Client.get("#{url}#{table_name}/ID/2", luck_header)
      response.body.should eq %({"id":2,"name":"her","genre":"Romance"})
    end
  end
  describe "UPDATE /table_name" do
    it "It will update a record in database" do
      update_json = (%({"id": 2,"name": "Matrix", "genre": "SCI-FI"}))
      response = HTTP::Client.patch("#{url}#{table_name}", luck_header, update_json)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
    end
    it "checks if data inserted correctly" do
      response = HTTP::Client.get("#{url}#{table_name}/ID/2", luck_header)
      response.body.should eq %({"id":2,"name":"Matrix","genre":"SCI-FI"})
    end
  end
  it "Checks if filter works fine" do
    json_str = %({"name": "Matrix", "genre": "SCI-FI"})
    response = HTTP::Client.get("http://#{url}#{table_name}/Exist", luck_header, json_str)
    response.body.should eq %({"id":2})
  end
  it "Checks if filter works fine" do
    json_str = %({"name": "Matrix"})
    response = HTTP::Client.get("http://#{url}#{table_name}/Exist", luck_header, json_str)
    response.body.should eq %({"id":2})
  end
  it "Checks if filter works fine" do
    json_str = %({"genre": "SCI-FI"})
    response = HTTP::Client.get("http://#{url}#{table_name}/Exist", luck_header, json_str)
    response.body.should eq %({"id":2})
  end
  it "Checks if filter works fine" do
    json_str = %({"genre": "Romance"})
    response = HTTP::Client.get("http://#{url}#{table_name}/Exist", luck_header, json_str)
    response.body.should eq %({"id":1})
  end
  it "Checks if filter works fine" do
    json_str = %({"name": "her"})
    response = HTTP::Client.get("http://#{url}#{table_name}/Exist", luck_header, json_str)
    response.body.should eq %({"id":1})
  end
  it "Delete the created table" do
    db_crud.db.exec("DROP TABLE #{table_name}")
  end
end

config = LuckConfig.new
if config.db_engine_name == "postgres"
  describe DBEngine do
    db_crud = DBEnginePostgres.new(config.db_url.not_nil!)

    describe "make_alphanumeric" do
      it "tests if the value is safe for sql table and column name" do
        db_crud.make_alphanumeric("b#45'po\"").should eq "b45po"
        db_crud.make_alphanumeric("aaa!@^ß(*98ß68as0df").should eq "aaaß98ß68as0df"
        # ap.make_alphanumeric("$tr_45ui-p^").should eq "tr_45ui-p"
      end
    end
    describe "make_create_table_str" do
      it "Gets a json and make query to create corrosponding table" do
        input_json = JSON.parse(%({"name": "varchar", "genre": "varchar"}))
        str, err = db_crud.make_create_table_str("Movie", input_json)
        str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
        err.should be_false
        str, err = db_crud.make_create_table_str("Mov%$ie", input_json)
        str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
        err.should be_false
        input_json = JSON.parse(%({"na@me": "varchar", "g!enre": "varchar"}))
        str, err = db_crud.make_create_table_str("Mov%$ie", input_json)
        str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
        err.should be_false
        str, err = db_crud.make_create_table_str("movieäß", input_json)
        str.should eq "CREATE TABLE movieäß(id SERIAL, name varchar, genre varchar)"
        err.should be_false
        input_json = JSON.parse(%({"name": "varchar", "genre": "varchar", "id": "varchar"}))
        str, err = db_crud.make_create_table_str("Movie", input_json)
        str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar, id varchar)"
        err.should be_true
      end
    end
    describe "make_insert_str" do
      it "Get a json and create insert query" do
        input_json = JSON.parse(%({"name": "Matrix", "genre": "SCI-FI"}))
        str, args = db_crud.make_insert_str("Movie", input_json)
        str.should eq "INSERT INTO Movie(name, genre) values($1, $2)"
        args.should eq ["Matrix", "SCI-FI"]
      end
    end
    describe "make_update_str" do
      it "Get a json and create update query" do
        input_json = JSON.parse(%({"id": 1,"name": "Matrix", "genre": "SCI-FI"}))
        str, args = db_crud.make_update_str("Movie", input_json)
        str.should eq "UPDATE Movie SET name=$1, genre=$2 WHERE id=$3"
        args.should eq ["Matrix", "SCI-FI", "1"]
      end
    end
    describe "make_filter_str" do
      it "make criterial for select statment" do
        cr = DBEnginePostgres.new(config.db_url.not_nil!)
        table_json = JSON.parse %({"name": "Matrix","genre": "SCI-FI"})
        str, args = cr.make_filter_str("Movie", table_json)
        str.should eq "name=$1 and genre=$2"
        args.should eq ["Matrix", "SCI-FI"]
      end
    end
  end

  # #Integration Tests goes here
  integration_test = ENV["integration_test"] ||= "false"
  table_name = "movie" + Time.utc.to_s("%s")
  new_db_name = "luckdb" + Time.utc.to_s("%s")
  luck_header = HTTP::Headers{"User-Agent" => "Crystal"}
  channel = Channel(Nil).new
  config = LuckConfig.new

  db_crud = DBEnginePostgres.new(config.db_url.not_nil!)

  if integration_test != false
    spawn same_thread: false do
      Log.info { "Program started" }
      api = APIParser.new(config.listen_port, db_crud)
      api.start
    end
    spawn same_thread: false do
      i = 3
      while i > 0
        pp "#{i} seconds to start integration test of luck CMS"
        sleep(1)
        i -= 1
      end
      it "raise an error if table definition is nil" do
        response = HTTP::Client.post("127.0.0.1:5800/object/#{table_name}", luck_header)
        response.body.should eq %({"error":true,"description":"table definition is null","err_id":1})
      end
      it "POST an invalid json for creating table" do
        data = %({"name": "varchar", "id": "varchar"})
        response = HTTP::Client.post("http://127.0.0.1:5800/object/#{table_name}", luck_header, data)
        response.body.should eq %({"error":true,"description":"could not create table","err_id":2})
      end
      channel.send(nil)
    end
    channel.receive
  end
  if integration_test == "postgres"
    spawn do
      luck_header = HTTP::Headers{"User-Agent" => "Crystal"}
      describe "Create a new dynamic db connection and test it" do
        it "Create a new db conection" do
          # response = HTTP::Client.post("127.0.0.1:5800/object/newdb",luck_header,%({"db_name: "newdb","db_host" : "127.0.0.1",
          # "db_password" : "",
          # "db_engine_name" : "sqlite3"}))
          data = %({"name": "varchar","dbname": "varchar","dbhost" : "varchar","dbpassword" : "varchar","dbenginename" : "varchar"})
          response = HTTP::Client.post("127.0.0.1:5800/object/#{new_db_name}", luck_header, data)
          response.body.should eq "DB::ExecResult(@rows_affected=0, @last_insert_id=0)"
        end
        it "Insert database connection to luck_db table" do
          data = %({"name": "#{new_db_name}", "dbname": "#{new_db_name}","dbhost": "127.0.0.1", "dbpassword": "444", "dbenginename" : "sqlite3"})
          response = HTTP::Client.post("127.0.0.1:5800/#{new_db_name}", luck_header, data)
          response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
        end
        it "" do
        end
      end
      do_test("127.0.0.1:5800/",db_crud,table_name,luck_header)
      do_test("127.0.0.1:5800/luck_db/#{new_db_name}/",db_crud,table_name,luck_header)
      channel.send(nil)
    end
    channel.receive
  end
end
