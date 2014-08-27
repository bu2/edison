#!/bin/bash

N=100

echo '# POST /auth/developer name="Bob" email="bob@yankee.com"'
time (curl -s -L -c cookie -F name="Bob" -F email="bob@yankee.com" http://localhost:4567/auth/developer/callback && echo) | jq '.'
echo
echo
echo

echo "${N}x"
echo '# POST /api/people {"firstname":"Bob","lastname":"Yankee","birthdate":"1999-01-01"}'
echo '# GET /api/people/$ID'
time for (( i = 0 ; i < $N ; ++i ))
do
    curl -X POST -s -L -b cookie -H 'Content-Type: application/json' -H 'Accept: application/json' --data '{"firstname":"Bob","lastname":"Yankee","birthdate":"1999-01-01"}' http://localhost:4567/api/people >result.json
    ID=$(cat result.json | jq --compact-output --raw-output '.id')
    curl -s -L -b cookie http://localhost:4567/api/people/$ID >/dev/null
    printf '.'
done
echo

echo "${N}x"
echo '# GET /api/people'
time for (( i = 0 ; i < $N ; ++i ))
do
    curl -s -L -b cookie http://localhost:4567/api/people >/dev/null
    printf '.'
done
