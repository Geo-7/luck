require "./spec_helper"

describe LuckConfig do
  describe "decrypt" do
    it "Decrypts a data with aes-256-cbc algoritm" do
      key = "RANDOM1400vat2412armAMDbobomiz44"
      iv = "rtyu2000tpk43320"
      config = LuckConfig.new
      config.decrypt(Base64.decode("7DU1IDYjkyB9ZvGYBdv2HQ"), key, iv).should eq "luck:myDBpass57"
    end
  end
end


