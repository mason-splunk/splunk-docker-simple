#!/usr/bin/env bash
sudo docker build -t splunk_simple:latest .
sudo docker run -d -p 8000:8000 -p 9997:9997 -p 8088:8088 -p 8191:8191 -t splunk_simple:latest
