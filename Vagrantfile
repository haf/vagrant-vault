# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "chef/centos-7.1"
  config.vm.box_check_update = true

  # config.vm.network "forwarded_port", guest: 80, host: 8080
  # config.vm.network "public_network"
  # config.vm.synced_folder "../data", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end

  config.vm.provision "shell", inline: <<-SHELL
    cd /root/

    yum update -y && yum upgrade -y
    yum install -y curl unzip epel-release yum-utils nginx vim
    mkdir -p /etc/vault /etc/consul/server /etc/consul/bootstrap /etc/consul-template
    mkdir -p /var/lib/consul
    mkdir -p /opt/consul-ui

    if [[ ! -f /usr/local/bin/consul ]]; then
      curl -L -o consul.zip https://dl.bintray.com/mitchellh/consul/0.5.2_linux_amd64.zip
      unzip consul.zip && mv consul /usr/local/bin && rm consul.zip

      curl -L -o consul-ui.zip https://dl.bintray.com/mitchellh/consul/0.5.2_web_ui.zip
      unzip consul-ui.zip && mv dist/ /opt/consul-ui && rm consul-ui.zip
    fi

    if [[ ! -f /usr/local/bin/vault ]]; then
      curl -L -o vault.zip https://dl.bintray.com/mitchellh/vault/vault_0.2.0_linux_amd64.zip
      unzip vault.zip && mv vault /usr/local/bin && rm vault.zip
    fi

    if [[ ! -f /usr/local/bin/consul-template ]]; then
      curl -L -o consul-template.zip https://github.com/hashicorp/consul-template/releases/download/v0.10.0/consul-template_0.10.0_linux_amd64.tar.gz
      tar xf consul-template.zip && mv consul-template_0.10.0_linux_amd64/consul-template /usr/local/bin && rm -rf consul-template_0.10.0_linux_amd64
    fi

    chmod +x /usr/local/bin/*
    chgrp -R root /usr/local/bin
    chown root /usr/local/bin/*

    if [[ ! $(grep '/usr/local/bin' /root/.bash_profile) ]]; then
      echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bash_profile
      echo 'export PATH=$PATH:/usr/local/bin' >> /vagrant/.bash_profile
      echo 'alias l="ls -lah"' >> /root/.bash_profile
      echo 'alias l="ls -lah"' >> /vagrant/.bash_profile
    fi

    cp '/vagrant/vault.hcl' '/etc/vault/vault.hcl'
    cp '/vagrant/consul-bootstrap.json' '/etc/consul/bootstrap/config.json'
    cp '/vagrant/consul-server.json' '/etc/consul/server/config.json'
    cp '/vagrant/consul.service' '/etc/systemd/system/consul.service'
    cp '/vagrant/vault.service' '/etc/systemd/system/vault.service'

  SHELL

  config.vm.define "vault-01", primary: true do |node|
    node.vm.hostname = 'vault-01'
    node.vm.network "private_network", ip: "192.168.33.10"
    # kill this manually, after the other two have run, then start consul through systemd:
    node.vm.provision "shell", inline: <<-SHELL
      [[ -f /etc/consul/server/bind.json ]] || echo '{ "bind_addr": "192.168.33.10" }' >> /etc/consul/server/bind.json
    SHELL
  end

  config.vm.define "vault-02" do |node|
    node.vm.hostname = 'vault-02'
    node.vm.network "private_network", ip: "192.168.33.20"
    node.vm.provision "shell", inline: <<-SHELL
      [[ -f /etc/consul/server/bind.json ]] || echo '{ "bind_addr": "192.168.33.20" }' >> /etc/consul/server/bind.json
      systemctl daemon-reload
      systemctl enable consul
      systemctl start consul
    SHELL
  end

  config.vm.define "vault-03" do |node|
    node.vm.hostname = 'vault-03'
    node.vm.network "private_network", ip: "192.168.33.30"

    # consul agent -config-dir /etc/consul/server &
    node.vm.provision "shell", inline: <<-SHELL
      [[ -f /etc/consul/server/bind.json ]] || echo '{ "bind_addr": "192.168.33.30" }' >> /etc/consul/server/bind.json
      systemctl daemon-reload
      systemctl enable consul
      systemctl start consul
    SHELL
  end

  config.vm.provision "shell", inline: <<-SHELL
    echo 'DONE!'
    systemctl daemon-reload
    systemctl enable consul
    systemctl start consul
  SHELL

  # now you can test it!
  # on vault-01:
  #   consul agent -server -bootstrap-expect 1 -data-dir /var/lib/consul/data
  #   CTRL+C
  #   systemctl start consul
  #   openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout /etc/pki/tls/private/vault.key -out /etc/pki/tls/private/vault.crt
  #     Country Name (2 letter code) [XX]:SE
  #     State or Province Name (full name) []:
  #     Locality Name (eg, city) [Default City]:Stockholm
  #     Organization Name (eg, company) [Default Company Ltd]:MyCompanyyy
  #     Organizational Unit Name (eg, section) []:Dev
  #     Common Name (eg, your name or your server's hostname) []:127.0.0.1:8200
  #   vault server -config=/etc/vault/vault.hcl
  #
  # on vault-01, other terminal:
  #   vault init -tls-skip-verify
  #   vault unseal -tls-skip-verify
  #   vault unseal -tls-skip-verify
  #   vault unseal -tls-skip-verify
  #
  #   # follow https://vaultproject.io/intro/getting-started/apis.html
end
