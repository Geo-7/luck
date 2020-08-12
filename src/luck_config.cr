class LuckConfig
    getter listen_port = 5800
    getter db_engine="sqlite3"
    getter db_url ="sqlite3://luck"
  
    def get_db_connection
    end
  
    # reads environment varibale
    def initialize
      begin
        key = "RANDOM1400vat2412armAMDbobomiz44"
        iv = "rtyu2000tpk43320"
        db_name = ENV.["luck_db_name"] ||= "luck"
        @db_engine = ENV.["luck_db_engine"] ||= "postgres"
        case @db_engine
        when "postgres"
          db_host = ENV.["luck_db_host"] ||= "127.0.0.1"
          db_password = ENV.["luck_db_password"]
          db_password = decrypt Base64.decode(db_password), key, iv ||= "moreluck"
          @db_url = "postgres://#{db_password}@#{db_host}/#{db_name}"
        when "sqlite3"
          db_url = "sqlite3://#{db_name}"
        else
          ...
        end
        @listen_port = (ENV.["luck_listen_port"] ||= "5800").to_i
      rescue ex
        p ex.message
        abort("DB connection string is not set ENV varibale")
        ex.message
      end
      
      #{@db_engine.not_nil!, @listen_port.not_nil!, @db_url.not_nil!}
    end
  
    # decrypt data
    def decrypt(data, key, iv)
      decipher = OpenSSL::Cipher.new "aes-256-cbc"
      decipher.decrypt
      decipher.key = key
      decipher.iv = iv
      dec_data = IO::Memory.new
      dec_data.write decipher.update(data)
      dec_data.write decipher.final
      dec_data.to_s
    end
  end