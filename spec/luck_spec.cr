require "./spec_helper"
describe LuckConfig do
  describe "decrypt" do
    it "Decrypts a data with aes-256-cbc algoritm" do
      key = "RANDOM1400vat2412armAMDbobomiz44"
      iv = "rtyu2000tpk43320"
      LuckConfig.decrypt(Base64.decode("7DU1IDYjkyB9ZvGYBdv2HQ"), key, iv).should eq "luck:myDBpass57"
    end
  end
end
describe APIParser do
  ap = APIParser.new(*LuckConfig.get_env)
  describe "find_tag" do
    it "find URL part which seperated by /" do
      ap.find_tag("podtan.com/api", 1).should eq "api"
      ap.find_tag("podtan.com/api/", 1).should eq "api"
      ap.find_tag("podtan.com/api/object", 2).should eq "object"
      ap.find_tag("podtan.com/api/object/", 2).should eq "object"
    end
  end
  describe "make_alphanumeric" do
    it "tests if the value is safe for sql table and column name" do
      ap.make_alphanumeric("b#45'po\"").should eq "b45po"
      ap.make_alphanumeric("aaa!@^ß(*98ß68as0df").should eq "aaaß98ß68as0df"
      # ap.make_alphanumeric("$tr_45ui-p^").should eq "tr_45ui-p"
    end
  end
  describe "make_create_table_str" do
    it "Gets a json and make query to create corrosponding table" do
      ap.db_engine = "postgres"
      input_json = JSON.parse(%({"name": "varchar", "genre": "varchar"}))
      str, err = ap.make_create_table_str("Movie", input_json)
      str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
      err.should be_false
      str, err = ap.make_create_table_str("Mov%$ie", input_json)
      str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
      err.should be_false
      input_json = JSON.parse(%({"na@me": "varchar", "g!enre": "varchar"}))
      str, err = ap.make_create_table_str("Mov%$ie", input_json)
      str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
      err.should be_false
      str, err = ap.make_create_table_str("movieäß", input_json)
      str.should eq "CREATE TABLE movieäß(id SERIAL, name varchar, genre varchar)"
      err.should be_false
      input_json = JSON.parse(%({"name": "varchar", "genre": "varchar", "id": "varchar"}))
      str, err = ap.make_create_table_str("Movie", input_json)
      str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar, id varchar)"
      err.should be_true
    end
  end
  describe "make_insert_str" do
    it "Get a json and create insert query" do
      ap.db_engine = "postgres"
      input_json = JSON.parse(%({"name": "Matrix", "genre": "SCI-FI"}))
      str, args = ap.make_insert_str("Movie", input_json)
      str.should eq "INSERT INTO Movie(name, genre) values($1, $2)"
      args.should eq ["Matrix", "SCI-FI"]
    end
  end
  describe "make_update_str" do
    it "Get a json and create update query" do
      input_json = JSON.parse(%({"id": 1,"name": "Matrix", "genre": "SCI-FI"}))
      ap.db_engine = "postgres"
      str, args = ap.make_update_str("Movie", input_json)
      str.should eq "UPDATE Movie SET name=$1, genre=$2 WHERE id=$3"
      args.should eq ["Matrix", "SCI-FI", "1"]
    end
  end
  describe "make_filter_str" do
    it "make criterial for select statment" do
      table_json = JSON.parse %({"name": "Matrix","genre": "SCI-FI"})
      str, args = ap.make_filter_str("Movie", table_json)
      str.should  eq "name=$1 and genre=$2"
      args.should  eq ["Matrix", "SCI-FI"]
    end
  end
end

# #Integration Tests goes here
integration_test = ENV["integration_test"] ||= "false"
table_name = "movie" + Time.utc.to_s("%s")
integration_test = ENV["integration_test"] ||= "false"
if integration_test == "postgres"
  channel = Channel(Nil).new
  spawn do
    ap = APIParser.new(*LuckConfig.get_env)
    ap.start
  end
  spawn do
    i = 3
    while i > 0
      puts "#{i} seoconds to start integration test of luck CMS"
      sleep(1)
      i -= 1
    end
    luck_header = HTTP::Headers{"User-Agent"=>"Crystal"}
    describe "POST /object/table_name" do
      it "POST a table json and make a table" do
        data = %({"name": "varchar", "genre": "varchar"})
        response = HTTP::Client.post("127.0.0.1:5800/object/#{table_name}", luck_header, data)
        response.body.should eq "DB::ExecResult(@rows_affected=0, @last_insert_id=0)"
      end
      it "raise an error if table definition is nil" do 
        response = HTTP::Client.post("127.0.0.1:5800/object/#{table_name}", luck_header)
        response.body.should eq %({"error":true,"description":"table definition is null","err_id":1})
      end
    end
    describe "POST /table_name" do
      it "Insert data to a table with a POST" do
        data = %({"name": "her", "genre": "Romance"})
        response = HTTP::Client.post("127.0.0.1:5800/#{table_name}", luck_header, data)
        response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
      end
      it "checks if data inserted correctly" do
        response = HTTP::Client.get("127.0.0.1:5800/#{table_name}", luck_header)
        response.body.should eq %([{"id":1,"name":"her","genre":"Romance"}])
      end
    end
    describe "POST /table_name" do
      it "Insert data to a table with a POST" do
        data = %({"name": "her", "genre": "Romance"})
        response = HTTP::Client.post("127.0.0.1:5800/#{table_name}", luck_header, data)
        response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
      end
      it "checks if data inserted correctly" do
        response = HTTP::Client.get("127.0.0.1:5800/#{table_name}", luck_header)
        response.body.should eq %([{"id":1,"name":"her","genre":"Romance"},{"id":2,"name":"her","genre":"Romance"}])
      end
      it "checks if data inserted correctly" do
        response = HTTP::Client.get("127.0.0.1:5800/#{table_name}/ID/1", luck_header)
        response.body.should eq %({"id":1,"name":"her","genre":"Romance"})
      end
      it "checks if data inserted correctly" do
        response = HTTP::Client.get("127.0.0.1:5800/#{table_name}/ID/2", luck_header)
        response.body.should eq %({"id":2,"name":"her","genre":"Romance"})
      end
    end
    describe "UPDATE /table_name" do
      it "It will update a record in database" do
        update_json = (%({"id": 2,"name": "Matrix", "genre": "SCI-FI"}))
        response = HTTP::Client.patch("127.0.0.1:5800/#{table_name}", luck_header, update_json)
        response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
      end
      it "checks if data inserted correctly" do
        response = HTTP::Client.get("127.0.0.1:5800/#{table_name}/ID/2", luck_header)
        response.body.should eq %({"id":2,"name":"Matrix","genre":"SCI-FI"})
      end
    end
    it "Checks if filter works fine" do
      json_str = %({"name": "Matrix", "genre": "SCI-FI"})
      response =HTTP::Client.get("http://127.0.0.1:5800/#{table_name}/Exist",luck_header,json_str)
      response.body.should eq %({"id":2}) 
    end
    it "Checks if filter works fine" do
      json_str = %({"name": "Matrix"})
      response =HTTP::Client.get("http://127.0.0.1:5800/#{table_name}/Exist",luck_header,json_str)
      response.body.should eq %({"id":2}) 
    end
    it "Checks if filter works fine" do
      json_str = %({"genre": "SCI-FI"})
      response =HTTP::Client.get("http://127.0.0.1:5800/#{table_name}/Exist",luck_header,json_str)
      response.body.should eq %({"id":2}) 
    end
    it "Checks if filter works fine" do
      json_str = %({"genre": "Romance"})
      response =HTTP::Client.get("http://127.0.0.1:5800/#{table_name}/Exist",luck_header,json_str)
      response.body.should eq %({"id":1}) 
    end
    it "Checks if filter works fine" do
      json_str = %({"name": "her"})
      response =HTTP::Client.get("http://127.0.0.1:5800/#{table_name}/Exist",luck_header,json_str)
      response.body.should eq %({"id":1}) 
    end
    
    it "POST an invalid json for creating table" do
      data = %({"name": "varchar", "id": "varchar"})
      response = HTTP::Client.post("http://127.0.0.1:5800/object/#{table_name}",luck_header, data)
      response.body.should eq %({"error":true,"description":"could not create table","err_id":2})
    end
    it "Delete the created table" do
      ap = APIParser.new(*LuckConfig.get_env)
      ap.db.exec("DROP TABLE #{table_name}")
    end
    channel.send(nil)
  end
  channel.receive
end
