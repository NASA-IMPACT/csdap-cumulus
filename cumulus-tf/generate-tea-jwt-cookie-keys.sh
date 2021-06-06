#!/usr/bin/env bash

_ssh_dir=${HOME}/.ssh
_keyfile=${_ssh_dir}/thin-egress-app-jwt-cookie.key

if [[ ! -f ${_keyfile} ]]; then
  # shellcheck disable=SC2174
  mkdir -p -m 0700 "${_ssh_dir}"
  ssh-keygen -q -t rsa -b 4096 -m PEM -f "${_keyfile}"
fi

echo "{\"rsa_priv_key\":\"$(openssl base64 -in "${_keyfile}" -A)\",\"rsa_pub_key\":\"$(openssl base64 -in "${_keyfile}.pub" -A)\"}"
