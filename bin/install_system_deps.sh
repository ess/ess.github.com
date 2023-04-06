#!/bin/sh

install_packages() {
  echo "Installing required system packages ..." &&

    apk --no-cache add --virtual build-deps build-base >/dev/null 2>&1 &&

    apk --no-cache add bash wget curl openssl bind-tools postgresql-dev python3 py3-pip git vim >/dev/null 2>&1
}



install_packages
