#!/bin/bash
set -x

git_env_setup(){
  git config --global core.sshCommand 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
  ssh-agent bash -c 'ssh-add /tmp/deployment.key'
  git clone git@server.com:user/repo.git /tmp/ansible-coreos
}


vault_parse(){
  local _store
  _store=$(curl -s http://169.254.169.254/latest/user-data | grep pulp-slave | awk '{print $1}' | base64 --decode)
  echo $_store > /tmp/ansible-coreos/ansible/vault-key.txt
}


inventory_generator(){
  local _instance_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
cat <<-EOF > /tmp/hosts
[coreos]
${_instance_ip}
[coreos:vars]
ansible_ssh_user=core
ansible_python_interpreter="/home/core/bin/python"
EOF
}
