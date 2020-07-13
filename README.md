# luck

Luck is a headless CMS

## Installation

crystal build src/luck.cr --release

## Usage
when you start the server if no environment variable has been set it will use sqlite3 engine and will create database file(luck):  
./luck  

Creating a new table with sqlite3 engine:  
curl -X POST 127.0.0.1:5800/object/movie --data '{"name": "string", "genre": "string"}'  
curl -X POST 127.0.0.1:5800/object/student --data '{"name" : "varchar","age" : "integer", "city" : "varchar"}'  

Insert data to database:  
curl -X POST http://127.0.0.1:5800/movie --data '{"name": "Matrix", "genre": "SCI-FI"}'  
curl -X POST http://127.0.0.1:5800/movie --data '{"name": "Interstellar", "genre": "SCI-FI"}'  
curl -X POST 127.0.0.1:5800/student --data '{"name" : "George","age" : 7, "city" : "moon"}'  
curl -X POST 127.0.0.1:5800/student --data '{"name" : "Joe","age" : 8, "city" : "moon"}'  


Reading data from database:  
curl -X GET http://127.0.0.1:5800/movie  
curl -X GET http://127.0.0.1:5800/student  

Deleting one row from database wit id:  
curl -X DELETE http://127.0.0.1:5800/movie --data '{"id":2}'

Updating data with id:  
curl -X PATCH http://127.0.0.1:5800/movie --data '{"id":2,"genre":"Romance"}'


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
