#!/bin/sh

echo "---- BUILDING BIZDOCK DATABASE IMAGE ----"
docker build -f ./bizdock_db/Dockerfile -t theagilefactory/bizdock_mariadb:10.1.12 .

echo "---- BUILDING BIZDOCK IMAGE ----"
docker build -f ./bizdock/Dockerfile -t theagilefactory/bizdock:11.0.1 .
