FROM ubuntu:latest

COPY . /script
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /script

RUN apt-get update &&\
    apt-get install -y awscli