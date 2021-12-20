#!/bin/sh
sudo apt-get update
sudo apt install -y jq azure-cli 
az storage blob download -c 'initial-script' \
                         -n 'main.sh' \
                         -f '/main.sh' \
                         --account-name '' \
                         --account-key ''
az storage blob download -c 'initial-script' \
                         -n 'function.sh' \
                         -f '/function.sh' \
                         --account-name '' \
                         --account-key ''
bash /main.sh
