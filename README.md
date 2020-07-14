# luck

Luck is a headless CMS

## Installation

crystal build src/luck.cr --release

## Usage
when you start the server if no environment variable has been set it will use sqlite3 engine and will create database file(luck):  
./luck  

To start a server with postgresql engine you shuld set some environmnet varibales or you use bash script like this:
`#!/bin/bash -x`  
`export luck_listen_port="5800"`  
`export luck_db_host="127.0.0.1"`  
`export luck_db_password="7DU1IDYjkyB9ZvGYBdv2HQ"`  
`export luck_db_engine="postgres"`  
`export luck_db_name="luck"`  
`./vat_admin >> log 2>&1 &`  
`disown`  
the above command will run the luck cms with and send it to background  
luck_db_password is "username:password" which is encrypted 

Creating a new table with sqlite3 engine:  
`curl -X POST http://127.0.0.1:5800/object/movie --data '{"name": "TEXT", "genre": "TEXT"}'`  
`curl -X POST http://127.0.0.1:5800/object/student --data '{"name" : "TEXT","age" : "integer", "city" : "TEXT"}'`

Creating a new table with postgres engine:  
`curl -X POST http://127.0.0.1:5600/object/movie --data '{"name": "varchar", "genre": "varchar"}'`

Insert data to database:  
`curl -X POST http://127.0.0.1:5800/movie --data '{"name": "Matrix", "genre": "SCI-FI"}'`  
`curl -X POST http://127.0.0.1:5800/movie --data '{"name": "Interstellar", "genre": "SCI-FI"}'`  
`curl -X POST 127.0.0.1:5800/student --data '{"name" : "George","age" : 7, "city" : "moon"}'`  
`curl -X POST 127.0.0.1:5800/student --data '{"name" : "Joe","age" : 8, "city" : "moon"}'`  


Reading data from database:  
`curl -X GET http://127.0.0.1:5800/movie`   
`curl -X GET http://127.0.0.1:5800/student`    

Deleting one row from database with id:  
`curl -X DELETE http://127.0.0.1:5800/movie --data '{"id":2}'`

Updating data with id:  
`curl -X PATCH http://127.0.0.1:5800/movie --data '{"id":2,"genre":"Romance"}'`


## Development

...

## Contributing

1. Fork it (<https://github.com/your-github-user/luck/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Geo-7](https://github.com/Geo-7) - creator and maintainer
