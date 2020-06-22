require "./spec_helper"
describe APIParser do
  describe "find_tag" do
    it "find URL part which seperated by /" do
        ap = APIParser.new
        ap.find_tag("podtan.com/api",1).should eq "api"
        ap.find_tag("podtan.com/api/",1).should eq "api"
        ap.find_tag("podtan.com/api/object",2).should eq "object"
        ap.find_tag("podtan.com/api/object/",2).should eq "object"
    end
  end
end

