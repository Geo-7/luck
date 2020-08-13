config = LuckConfig.new
if config.db_engine == "sqlite3"
  describe Cruder do
    config = LuckConfig.new
    db_crud = CruderSqlite3.new(config.db_url.not_nil!)
    
    describe "make_alphanumeric" do
      it "tests if the value is safe for sql table and column name" do
        db_crud.make_alphanumeric("b#45'po\"").should eq "b45po"
        db_crud.make_alphanumeric("aaa!@^ß(*98ß68as0df").should eq "aaaß98ß68as0df"
        # ap.make_alphanumeric("$tr_45ui-p^").should eq "tr_45ui-p"
      end
    end
    describe "make_create_table_str" do
      it "Gets a json and make query to create corrosponding table" do
        
        input_json = JSON.parse(%({"legs": "TEXT", "att": "TEXT", "hands": "INTEGER"}))
        str, err = db_crud.make_create_table_str("Monkey", input_json)
        str.should eq "CREATE TABLE Monkey(id INTEGER PRIMARY KEY, legs TEXT, att TEXT, hands INTEGER)"
        err.should be_false
        input_json = JSON.parse(%({"name": "TEXT", "genre": "TEXT"}))
        str, err = db_crud.make_create_table_str("Movie", input_json)
        str.should eq "CREATE TABLE Movie(id INTEGER PRIMARY KEY, name TEXT, genre TEXT)"
        err.should be_false
        input_json = JSON.parse(%({"legs": "TEXT", "att": "TEXT", "hands": "INTEGER", "ID": "serial"}))
        str, err = db_crud.make_create_table_str("Monkey", input_json)
        str.should eq "CREATE TABLE Monkey(id INTEGER PRIMARY KEY, legs TEXT, att TEXT, hands INTEGER, ID serial)"
        err.should be_true
        input_json = JSON.parse(%({"legs": "TEXT", "att": "TEXT", "hands": "INTEGER", "id": "TEXT"}))
        str, err = db_crud.make_create_table_str("Monkey", input_json)
        str.should eq "CREATE TABLE Monkey(id INTEGER PRIMARY KEY, legs TEXT, att TEXT, hands INTEGER, id TEXT)"
        err.should be_true
      end
    end
    describe "make_insert_str" do
      it "Get a json and create insert query" do
        input_json = JSON.parse(%({"name": "Matrix", "genre": "SCI-FI"}))
        str, args = db_crud.make_insert_str("Movie", input_json)
        str.should eq "INSERT INTO Movie(name, genre) values(?, ?)"
        args.should eq ["Matrix", "SCI-FI"]
      end
    end
    describe "make_update_str" do
      it "Get a json and create update query" do
        input_json = JSON.parse(%({"id": 1,"name": "Matrix", "genre": "SCI-FI"}))
        str, args = db_crud.make_update_str("Movie", input_json)
        str.should eq "UPDATE Movie SET name=?, genre=? WHERE id=?"
        args.should eq ["Matrix", "SCI-FI", "1"]
      end
    end
    describe "cast_type" do
      it "Get a value and cast it to proper type" do
        db_crud.cast_type("false").should be_false
        db_crud.cast_type("true").should be_true
        db_crud.cast_type("2").should eq 2.0
        db_crud.cast_type("myName").should eq "myName"
      end
    end
  end

  # #Integration Tests goes here
  integration_test = ENV["integration_test"] ||= "false"
  table_name = "movie" + Time.utc.to_s("%s")
  luck_header = HTTP::Headers{"User-Agent" => "Crystal"}
  channel = Channel(Nil).new
  config = LuckConfig.new
  db_crud = CruderSqlite3.new(config.db_url.not_nil!)
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
  if integration_test == "sqlite3"
    spawn same_thread: false do
      describe "POST /object/table_name" do
        it "POST a table json and make a table" do
          data = %({"name": "TEXT", "genre": "TEXT"})
          response = HTTP::Client.post("127.0.0.1:5800/object/#{table_name}", HTTP::Headers{"User-Agent" => "Crystal"}, data)
          response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=1)"
        end
      end
      describe "POST /table_name" do
        it "Insert data to a table with a POST" do
          data = %({"name": "her", "genre": "SCI-FI"})
          response = HTTP::Client.post("127.0.0.1:5800/#{table_name}", HTTP::Headers{"User-Agent" => "Crystal"}, data)
          response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=1)"
        end
      end
      describe "POST /table_name" do
        it "Insert data to a table with a POST" do
          data = %({"name": "her", "genre": "Romance"})
          response = HTTP::Client.post("127.0.0.1:5800/#{table_name}", HTTP::Headers{"User-Agent" => "Crystal"}, data)
          response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=2)"
        end
      end
      describe "DELETE /table_name" do
        it "It will delete a record from database with an its ID" do
          delete_json = %({"id": 1})
          response = HTTP::Client.delete("127.0.0.1:5800/#{table_name}", HTTP::Headers{"User-Agent" => "Crystal"}, delete_json)
          response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=2)"
        end
      end
      describe "UPDATE /table_name" do
        it "It will update a record in database" do
          update_json = (%({"id": 2,"name": "Matrix", "genre": "SCI-FI"}))
          response = HTTP::Client.patch("127.0.0.1:5800/#{table_name}", HTTP::Headers{"User-Agent" => "Crystal"}, update_json)
          response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=2)"
        end
      end
      channel.send(nil)
    end
    channel.receive
  end
end
