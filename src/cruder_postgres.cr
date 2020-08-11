require "./cruder"
require "pg"
require "db"
class CruderPostgres < Cruder
    @db : DB::Database
    def initialize(db_url : String)
        @db = DB.open(db_url)
    end
    def read(table_name)
    end

end