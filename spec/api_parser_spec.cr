describe APIParser do
    config = LuckConfig.new
    db_crud = DBEngineSqlite3.new(config.db_url.not_nil!)
    ap = APIParser.new(config.listen_port, db_crud)
    describe "find_tag" do
      it "find URL part which seperated by /" do
        ap.find_tag("podtan.com/api", 1).should eq "api"
        ap.find_tag("podtan.com/api/", 1).should eq "api"
        ap.find_tag("podtan.com/api/object", 2).should eq "object"
        ap.find_tag("podtan.com/api/object/", 2).should eq "object"
      end
    end
end