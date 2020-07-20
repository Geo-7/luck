#!/bin/bash -x
export luck_listen_port="5800"
export luck_db_host="127.0.0.1"
export luck_db_password="7DU1IDYjkyB9ZvGYBdv2HQ"
export luck_db_engine="sqlite3"
export luck_db_name="luck"
export integration_test="sqlite3"
crystal spec
