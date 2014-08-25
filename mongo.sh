#!/bin/bash

DBPATH=./mongodb

mkdir -p "$DBPATH"

mongod --dbpath "$DBPATH"
