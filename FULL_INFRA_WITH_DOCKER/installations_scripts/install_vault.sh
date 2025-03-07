#!/bin/bash

#-----------------------------------------------------------------------------------------------------------------------#
# Date : 28 JAN 2025                                                                                                    #
# Description : This script file allows you to configure HASHICORP VAULT SERVER using Docker                            #
# Write By : Hermann90 for Utrains                                                                                      #
#-----------------------------------------------------------------------------------------------------------------------#

confirm_installation_step () {
	if [ $? -eq 0 ]; then
        echo "$(tput setaf 2) ################################################################# $(tput sgr 0)"
		echo "$(tput setaf 2) >>>>>>>>>>>>>>>> $1 : $2 SUCESS <<<<<<<<<<<<<<<<$(tput sgr 0)"
        echo "$(tput setaf 2) $2 is installed Successfully $(tput sgr 0)"
        echo "$(tput setaf 2) >>>>>>>>>>>>>>>> Thanks to configure $2 <<<<<<<<<<<<<<<< $(tput sgr 0)"
        echo "$(tput setaf 2) ################################################################# $(tput sgr 0)"

	else
        echo "$(tput setaf 1) **************** $1 : Service $2 Failled **************** $(tput sgr 0)"
		echo "$(tput setaf 2) Sorry, we can't continue with this installation. Please check why the $2 service has not been installed. $(tput sgr 0)"
		exit 1
	fi
} 


echo "$(tput setaf 4)  >>>>>>>>>>>>>> VAULT CONFIGURATION <<<<<<<<<<<<<<<  $(tput sgr 0)"


sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install vault
export VAULT_CONFIG=/etc/vault.d
export VAULT_BINARY=/usr/bin/vault

sudo tee /lib/systemd/system/vault.service <<EOF
[Unit]
Description="HashiCorp Vault"
Documentation="https://developer.hashicorp.com/vault/docs"
ConditionFileNotEmpty="${VAULT_CONFIG}/vault.hcl"

[Service]
User=vault
Group=vault
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=${VAULT_BINARY} server -config=${VAULT_CONFIG}/vault.hcl
ExecReload=/bin/kill --signal HUP
KillMode=process
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 644 /lib/systemd/system/vault.service
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault



# create vault config file
sudo systemctl stop vault  || echo "Vault is not running"
sudo rm -rf /etc/vault.d/vault.hcl || echo "config file not found"

sudo tee /etc/vault.d/vault.hcl <<EOF
storage "file" {
  path = "/opt/vault/data"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
ui = true
EOF
# generate vault key
rm -rf /opt/vault/data || echo ""
systemctl start vault

confirm_installation_step "STEP 1" "VAULT"

sleep 5
vault operator init --address http://127.0.0.1:8200 -key-shares=1 -key-threshold=1 > vaultkey.txt

