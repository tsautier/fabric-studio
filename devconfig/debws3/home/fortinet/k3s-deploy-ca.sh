#!/bin/bash

sudo cp certificates/fortidemoCA.crt /usr/local/share/ca-certificates/ 
sudo update-ca-certificates
