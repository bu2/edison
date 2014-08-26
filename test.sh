#!/bin/bash

echo '# GET /api/people (before authentication!)'
(curl -s -L http://localhost:4567/api/people && echo) | jq '.'
echo
echo
echo
echo '# POST /auth/developer name="Bob" email="bob@yankee.com"'
(curl -s -L -c cookie -F name="Bob" -F email="bob@yankee.com" http://localhost:4567/auth/developer/callback && echo) | jq '.'
echo
echo
echo
echo '# GET /api/people'
(curl -s -L -b cookie http://localhost:4567/api/people && echo) | jq '.'
echo
echo '# POST /api/people {"firstname":"Bob","lastname":"Yankee","birthdate":"1999-01-01"}'
( curl -X POST -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Bob","lastname":"Yankee","birthdate":"1999-01-01"}' http://localhost:4567/api/people && echo ) | tee result.json | jq '.'
echo
ID=$(cat result.json | jq --compact-output --raw-output '.id')
echo "# ID = $ID"
echo
echo '# GET /api/people/$ID'
( curl -s -L -b cookie http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# PUT /api/people/$ID {"firstname":"Bobo","lastname":"Yankiz","birthdate":"2001-01-01"}'
(curl -X PUT -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Bobo","lastname":"Yankiz","birthdate":"2001-01-01"}' http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# GET /api/people/$ID'
(curl -s -L -b cookie http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# PUT /api/people/$ID {"lastname":"Mr X","birthdate":"1950-01-01", "place":"nowhere"}'
(curl -X PUT -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"lastname":"Mr X","birthdate":"1950-01-01", "place":"nowhere"}' http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# GET /api/people/$ID'
(curl -s -L -b cookie http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# PATCH /api/people/$ID {"place":"anywhere", "email": "mr.x@anonymous.org"}'
(curl -X PATCH -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"place":"anywhere", "email": "mr.x@anonymous.org"}' http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# GET /api/people/$ID'
(curl -s -L -b cookie http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo
echo
echo '# POST /api/people {"firstname":"Homer","lastname":"Simpson","birthdate":"1970-01-01"}'
( curl -X POST -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Homer","lastname":"Simpson","birthdate":"1970-01-01"}' http://localhost:4567/api/people && echo ) | jq '.'
echo
echo '# POST /api/people {"firstname":"Foo","lastname":"Bar","birthdate":"2014-01-01"}'
( curl -X POST -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Foo","lastname":"Bar","birthdate":"2014-01-01"}' http://localhost:4567/api/people && echo ) | jq '.'
echo
echo '# GET /api/people'
(curl -s -L -b cookie http://localhost:4567/api/people && echo) | jq '.'
echo
echo '# POST /api/people/find {"lastname": "Bar"}'
(curl -X POST -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"lastname": "Bar"}' http://localhost:4567/api/people/find && echo) | jq '.'
echo
echo '# POST /api/people/find {"birthdate": { "$lt": "2000-01-01"} }'
(curl -X POST -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"birthdate": { "$lt": "2000-01-01"}}' http://localhost:4567/api/people/find && echo) | jq '.'
echo
echo '# DELETE /api/people/$ID'
(curl -X DELETE -s -L -b cookie --data '' http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# GET /api/people/$ID'
(curl -s -L -b cookie http://localhost:4567/api/people/$ID && echo) | jq '.'
echo
echo '# GET /api/people'
(curl -s -L -b cookie http://localhost:4567/api/people && echo) | jq '.'
echo
