#!/bin/bash -x
export luck_listen_port="5800"
export luck_db_host="172.17.0.2"
export luck_db_password="7DU1IDYjkyB9ZvGYBdv2HQ"
export luck_db_engine="postgres"
export luck_db_name="luck"
export integration_test="postgres"
crystal spec -Dpreview_mt