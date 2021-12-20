#!/bin/bash -xe
source /function.sh

log "Start scripting"
log "update apt packages"
apt upgrade -y

MACHINE_TAG=`curl -H Metadata:true http://169.254.169.254/metadata/instance/compute/tagsList?api-version=2019-06-04`

IS_INSTALL_DOCKER=`echo $MACHINE_TAG | jq -r '.[] | select(.name == "docker").value'`
if [[ "$IS_INSTALL_DOCKER" == "yes" ]]; then
    log "DOCKER Install ... "
    sudo apt-get install -y \
                  ca-certificates \
                  curl \
                  gnupg \
                  lsb-release
    sudo apt-get -y install docker.io
    sudo service docker start
    sudo usermod -a -G docker azureuser
    log "DOCKER Install Successfully"

    log "DOCKER-COMPOSE Install ... "
    sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" \
              -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    sudo systemctl enable docker
    log "DOCKER-COMPOSE Install Successfully "
fi;


SERVICE=`echo $MACHINE_TAG | jq -r '.[] | select(.name == "service").value'`
log "download $SERVICE install script"
az storage blob download -c 'initial-script' \
                         -n "$SERVICE/install.sh" \
                         -f "/install.sh" \
                         --account-name '' \
                         --account-key ''

bash /install.sh "${MACHINE_TAG}"
log "End scripting"