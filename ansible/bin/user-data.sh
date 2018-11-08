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

write_files:
  - path: /root/.ssh/deployment.key
    permissions: 0600
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      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
      -----END RSA PRIVATE KEY-----

  - path: /root/.ssh/config
    permissions: 0644
    content: |
      Host github.com
      Port 22
      Hostname github.com
      IdentityFile "/root/.ssh/deployment.key"
      TCPKeepAlive yes
      IdentitiesOnly yes
      StrictHostKeyChecking no

  - path: /etc/ssh/sshd_config
    permissions: 0644
    content: |
      Subsystem sftp internal-sftp
      ClientAliveInterval 180
      UseDNS no
      UsePAM yes
      PrintLastLog no # handled by PAM
      PrintMotd no # handled by PAM
      AuthenticationMethods publickey
      AuthorizedKeysCommand /opt/bin/authorized_key_command.sh
      AuthorizedKeysCommandUser root

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

      git_clone_setup() {
        if [[ -d /tmp/coreos-bootstrap ]]; then
          rm -rf /tmp/coreos-bootstrap
        fi
        git clone git@github.com:sohel2020/coreos-bootstrap.git /tmp/coreos-bootstrap
      }


      vault_parse(){
        local _store
        _store=$(curl -s http://169.254.169.254/latest/user-data | grep vaultpass | awk '{print $4}' | tail -n 1 | base64 --decode)
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
            --rm=true -v /srv/ssh:/srv/ssh \
            -v /tmp/coreos-bootstrap/ansible:/tmp/coreos-bootstrap/ansible \
            -w /tmp/coreos-bootstrap/ansible \
            ansible/centos7-ansible:stable ansible-playbook --vault-password-file=vault-key.txt -i hosts --connection=paramiko --private-key=/srv/ssh/ansible site.yaml
      }

      git_clone_setup
      vault_parse
      setup_ssh_keys
      inventory_generator
      run_docker
      # vaultpass : a2J1RWF5dzc2Z2NwCg==
