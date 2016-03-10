#!/bin/sh

echo "---- BUILDING BIZDOCK DATABASE IMAGE ----"
docker build -f ./bizdock_db/Dockerfile -t taf/bizdock_mariadb:10.1.12 .

echo "---- BUILDING BIZDOCK IMAGE ----"
docker build -f ./bizdock/Dockerfile -t taf/bizdock:11.0.1 .
