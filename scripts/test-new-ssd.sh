#!/bin/bash

sudo smartctl -H $1
sudo smartctl -a $1

sudo smartctl -t short $1
sleep 2m
sudo smartctl -l selftest $1
