#cloud-config
coreos:
  units:
    - name: docker-tcp.socket
      command: start
      enable: true
      content: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=2375
        Service=docker.service
        BindIPv6Only=both

        [Install]
        WantedBy=sockets.target

    - name: bootstrap.service
      command: start
      content: |
        [Unit]
        Description=Bootstraps the node
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/root/bootstrap.sh
update:
    reboot-strategy: off
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDdUn7MngzRWLusJ+9S2MSibbJjkxV0fa5D6fUKJnGuYHxgL3vpMi+TLWRUIFv9tmBIxard8nS4/mNu6P0ENm5LmkAYPJngEMbCoQmpk89tbQIrlZrhr5FffP3fJfxzahEtYjEtNuBQuuMwrXN3hvuehVGWEu1lFG6WLYnejL0au2L4CJhCoV2g+b/uqTjsFVHhbGWvuazYL9SJmH2mWqEnbj2tj7goemU88bycisrMIvpKVWhu02KM2FUHgPwtoENi909LTpiD/y+3FzBwa7cpMNjmTmrzPbJTZ7gNNzSpPWHtCejE/B06+7lxSzbeRQP6q1Xb++bcVWODvh6qCb4b

write_files:
  - path: /tmp/deployment.pem
    permissions: 0644
    content: |
      #!/usr/bin/bash
      if [[ -d /lib/pam.d ]]; then
        rsync -a /lib/pam.d/ /etc/pam.d/
        sed -i '/pam_systemd.so/d' /etc/pam.d/*
        sed -i '/pam_nologin.so/d' /etc/pam.d/*
      fi
write_files:
  - path: /root/bootstrap.sh
    permissions: 0755
    content: |
      #!/usr/bin/bash
      #
      declare -r ssh_dir=/srv/ssh
      declare -r ansible_playbook=site.yaml

      if [ -f /etc/coreos/update.conf ] ; then
        rm  /etc/coreos/update.conf
      fi

      git_env_setup() {
        git config --global core.sshCommand 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
        ssh-agent bash -c 'ssh-add /tmp/deployment.pem'
        if [[ -d /tmp/coreos-bootstrap ]]; then
          rm -rf /tmp/coreos-bootstrap
        fi
        git clone git@server.com:user/coreos-bootstrap.git /tmp/coreos-bootstrap
      }


      vault_parse(){
        local _store
        _store=$(curl -s http://169.254.169.254/latest/user-data | grep pulp-slave | awk '{print $1}' | base64 --decode)
        echo $_store > /tmp/coreos-bootstrap/ansible/vault-key.txt
      }

      setup_ssh_keys() {
        if [ ! -d ${ssh_dir} ] ; then
          mkdir $ssh_dir
        fi
        if [ ! -f ${ssh_dir}/ansible ] ; then
          chown core:core $ssh_dir
          ssh-keygen -b 2048 -t rsa -f ${ssh_dir}/ansible -q -N ""
          cp ${ssh_dir}/ansible.pub /home/core/.ssh/authorized_keys.d
          update-ssh-keys
        fi
      }

      inventory_generator() {
      local _instance_ip=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
      cat <<-EOF > /tmp/coreos-bootstrap/ansible/hosts
      [coreos]
      ${_instance_ip}
      [coreos:vars]
      ansible_ssh_user=core
      ansible_python_interpreter="/home/core/bin/python"
      EOF
      }

      run_docker() {
        docker run --net=host \
            --rm=true -v ${ssh_dir}:/srv/ssh \
            -v /tmp/coreos-bootstrap/ansible:/tmp/coreos-bootstrap/ansible \
            -w /tmp/coreos-bootstrap/ansible \
            -e ANSIBLE_SSH_KEY=${ssh_dir}/ansible \
            -e ANSIBLE_PLAYBOOK=${ansible_playbook} \
            ansible/centos7-ansible:stable ansible-playbook --vault-password-file=vault-key.txt -i hosts --connection=paramiko --private-key=${ANSIBLE_SSH_KEY?} ${ANSIBLE_PLAYBOOK?}
      }
      exit 0
