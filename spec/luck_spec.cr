require "./spec_helper"
describe APIParser do
  ap = APIParser.new
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
      input_json = JSON.parse(%({"legs": "TEXT", "att": "TEXT", "hands": "INTEGER"}))
      str = ap.make_create_table_str("Monkey", input_json)
      str.should eq "CREATE TABLE Monkey(id INTEGER PRIMARY KEY, legs TEXT, att TEXT, hands INTEGER)"
      input_json = JSON.parse(%({"name": "varchar", "genre": "varchar"}))
      str = ap.make_create_table_str("Movie", input_json)
      str.should eq "CREATE TABLE Movie(id INTEGER PRIMARY KEY, name varchar, genre varchar)"
      ap.db_engine = "postgres"
      str = ap.make_create_table_str("Movie", input_json)
      str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
      str = ap.make_create_table_str("Mov%$ie", input_json)
      str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
      input_json = JSON.parse(%({"na@me": "varchar", "g!enre": "varchar"}))
      str = ap.make_create_table_str("Mov%$ie", input_json)
      str.should eq "CREATE TABLE Movie(id SERIAL, name varchar, genre varchar)"
      str = ap.make_create_table_str("movieäß", input_json)
      str.should eq "CREATE TABLE movieäß(id SERIAL, name varchar, genre varchar)"
    end
  end
  describe "make_insert_str" do
    it "Get a json and create insert query" do
      input_json = JSON.parse(%({"name": "Matrix", "genre": "SCI-FI"}))
      ap.db_engine = "sqlite3"
      str, args = ap.make_insert_str("Movie", input_json)
      str.should eq "INSERT INTO Movie(name, genre) values(?, ?)"
      args.should eq ["Matrix", "SCI-FI"]
      ap.db_engine = "postgres"
      str.should eq "INSERT INTO Movie(name, genre) values(?, ?)"
      args.should eq ["Matrix", "SCI-FI"]
    end
  end
  describe "make_update_str" do
    it "Get a json and create update query" do
      input_json = JSON.parse(%({"id": 1,"name": "Matrix", "genre": "SCI-FI"}))
      ap.db_engine = "sqlite3"
      str,args = ap.make_update_str("Movie", input_json)
      str.should eq "UPDATE Movie SET name=?, genre=? WHERE id=?"
      args.should eq ["Matrix", "SCI-FI", "1"]
      ap.db_engine = "postgres"
      str,args = ap.make_update_str("Movie", input_json)
      str.should eq "UPDATE Movie SET name=$1, genre=$2 WHERE id=$3"
      args.should eq ["Matrix", "SCI-FI", "1"]
    end
  end
  describe "cast_type" do
    it "Get a value and cast it to proper type" do
      ap.cast_type("false").should be_false
      ap.cast_type("true").should be_true
      ap.cast_type("2").should eq 2.0
      ap.cast_type("myName").should eq "myName"
    end
  end
  describe "decrypt" do
    it "Decrypts a data with aes-256-cbc algoritm" do
      key = "RANDOM1400vat2412armAMDbobomiz44"
      iv = "rtyu2000tpk43320"
      ap.decrypt(Base64.decode("7DU1IDYjkyB9ZvGYBdv2HQ"), key, iv).should eq "luck:myDBpass57"
    end
  end
end

# #Integration Tests goes here
integration_test = ENV["integration_test"] ||= "false"
if integration_test == "sqlite3"
  describe "POST /object/table_name" do
    it "POST a table json and make a table" do
      data = %({"name": "TEXT", "genre": "TEXT"})
      response = HTTP::Client.post("127.0.0.1:5800/object/movie", HTTP::Headers{"User-Agent" => "Crystal"}, data)
      response.body.should eq "DB::ExecResult(@rows_affected=0, @last_insert_id=0)"
    end
  end
  describe "POST /table_name" do
    it "Insert data to a table with a POST" do
      data = %({"name": "her", "genre": "SCI-FI"})
      response = HTTP::Client.post("127.0.0.1:5800/movie", HTTP::Headers{"User-Agent" => "Crystal"}, data)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=1)"
    end
  end
  describe "POST /table_name" do
    it "Insert data to a table with a POST" do
      data = %({"name": "her", "genre": "Romance"})
      response = HTTP::Client.post("127.0.0.1:5800/movie", HTTP::Headers{"User-Agent" => "Crystal"}, data)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=2)"
    end
  end
  describe "DELETE /table_name" do
    it "It will delete a record from database with an its ID" do
      delete_json = %({"id": 1})
      response = HTTP::Client.delete("127.0.0.1:5800/movie", HTTP::Headers{"User-Agent" => "Crystal"}, delete_json)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=2)"
    end
  end
  describe "UPDATE /table_name" do
    it "It will update a record in database" do
      update_json = (%({"id": 2,"name": "Matrix", "genre": "SCI-FI"}))
      response =HTTP::Client.patch("127.0.0.1:5800/movie",HTTP::Headers{"User-Agent" => "Crystal"}, update_json)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=2)"
    end
  end
end
integration_test = ENV["integration_test"] ||= "false"
if integration_test == "postgres"
  describe "POST /object/table_name" do
    it "POST a table json and make a table" do
      data = %({"name": "varchar", "genre": "varchar"})
      response = HTTP::Client.post("127.0.0.1:5800/object/movie", HTTP::Headers{"User-Agent" => "Crystal"}, data)
      response.body.should eq "DB::ExecResult(@rows_affected=0, @last_insert_id=0)"
    end
  end
  describe "POST /table_name" do
    it "Insert data to a table with a POST" do
      data = %({"name": "her", "genre": "SCI-FI"})
      response = HTTP::Client.post("127.0.0.1:5800/movie", HTTP::Headers{"User-Agent" => "Crystal"}, data)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
    end
  end
  describe "POST /table_name" do
    it "Insert data to a table with a POST" do
      data = %({"name": "her", "genre": "Romance"})
      response = HTTP::Client.post("127.0.0.1:5800/movie", HTTP::Headers{"User-Agent" => "Crystal"}, data)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
    end
  end
  describe "DELETE /table_name" do
    it "It will delete a record from database with an its ID" do
      delete_json = %({"id": 1})
      response = HTTP::Client.delete("127.0.0.1:5800/movie", HTTP::Headers{"User-Agent" => "Crystal"}, delete_json)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
    end
  end
  describe "UPDATE /table_name" do
    it "It will update a record in database" do
      update_json = (%({"id": 2,"name": "Matrix", "genre": "SCI-FI"}))
      response =HTTP::Client.patch("127.0.0.1:5800/movie",HTTP::Headers{"User-Agent" => "Crystal"}, update_json)
      response.body.should eq "DB::ExecResult(@rows_affected=1, @last_insert_id=0)"
    end
  end
end