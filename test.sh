#!/bin/bash

echo '# GET /api/people'
(curl -s http://localhost:4567/api/people && echo) | jq '.'
echo
echo '# POST /api/people {"firstname":"Bob","lastname":"Yankee","birthdate":"1999-01-01"}'
( curl -X POST -s -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Bob","lastname":"Yankee","birthdate":"1999-01-01"}' http://localhost:4567/api/people && echo ) | tee result.json | jq '.'
echo
ID=$(cat result.json | jq --compact-output --raw-output '.id')
echo "# ID = $ID"
echo
echo '# GET /api/people/$ID'
( curl -s http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# PUT /api/people/$ID {"firstname":"Bobo","lastname":"Yankiz","birthdate":"2001-01-01"}'
(curl -X PUT -s -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Bobo","lastname":"Yankiz","birthdate":"2001-01-01"}' http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# GET /api/people/$ID'
(curl -s http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo
echo
echo '# POST /api/people {"firstname":"Homer","lastname":"Simpson","birthdate":"1970-01-01"}'
( curl -X POST -s -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Homer","lastname":"Simpson","birthdate":"1970-01-01"}' http://localhost:4567/api/people && echo ) | jq '.'
echo
echo '# POST /api/people {"firstname":"Foo","lastname":"Bar","birthdate":"2014-01-01"}'
( curl -X POST -s -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Foo","lastname":"Bar","birthdate":"2014-01-01"}' http://localhost:4567/api/people && echo ) | jq '.'
echo
echo '# GET /api/people'
(curl -s http://localhost:4567/api/people && echo) | jq '.'
echo
