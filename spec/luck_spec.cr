require "./spec_helper"
describe APIParser do
  ap = APIParser.new
  describe "find_tag" do
    it "find URL part which seperated by /" do
        ap.find_tag("podtan.com/api",1).should eq "api"
        ap.find_tag("podtan.com/api/",1).should eq "api"
        ap.find_tag("podtan.com/api/object",2).should eq "object"
        ap.find_tag("podtan.com/api/object/",2).should eq "object"
    end
  end
  describe "make_create_table_str" do
    it "Gets a json and make query to create corrosponding table" do
      json_str = %({"legs": "string", "att": "string", "hands": "INTEGER"})
      json_table = JSON.parse(json_str)
      str = ap.make_create_table_str("Monkey",json_table)
      str.should eq "CREATE TABLE Monkey(ID INTEGER PRIMARY KEY, legs string, att string, hands INTEGER)"
    end 
  end
end

describe "POST /object/table_name" do
  it "POST a table json and make a table" do
    data = %({"name": "string", "att": "string"})
    response = HTTP::Client.post("127.0.0.1:5800/object/mov", HTTP::Headers{"User-Agent" => "Crystal"},data)
    response.body.should eq "DB::ExecResult(@rows_affected=0, @last_insert_id=0)"
  end
end

