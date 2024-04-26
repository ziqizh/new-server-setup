#!/bin/bash

show_menu() {
    echo "Choose an option:"
    echo "1) Setup account as root"
    echo "2) Install Docker"
    echo "3) Install v2ray"
    echo "4) Install FRP Server"
    echo "9) Exit"
}

setup_docker() {
	# https://docs.docker.com/engine/install/ubuntu/
	echo "Removing old dependencies..."
	for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
	sudo apt-get update
	sudo apt-get install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	echo \
  	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  	$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

}

generate_number() {
	local MIN=$1
	local MAX=$2
	local randomNumber=$(( MIN + RANDOM % (MAX - MIN + 1) ))
	echo $randomNumber
}

generate_password() {
    local password_length=$1
    local password=$(tr -dc 'A-Za-z0-9_@#' < /dev/urandom | head -c $password_length)
    echo $password
}

setup_frps() {
	FRPS_TEMPLATE="frps_template.toml"
	FRPC_TEMPLATE="frpc_template.toml"
	DOCKER_TEMPLATE="docker-compose.yml"
	mkdir ../local-config
	FRPS_OUTPUT="../local-config/frps.toml"
	FRPC_OUTPUT="../local-config/frpc.toml"
	DOCKER_OUTPUT="../local-config/docker-compose.yml"
	BIND_PORT=$(generate_number 5000 6000)
	DASHBOARD_PWD=$(generate_password 12)
	TOKEN=$(generate_password 12)
	echo "BIND_PORT $BIND_PORT, DASHBOARD_PWD: $DASHBOARD_PWD, TOKEN: $TOKEN"
	if [ ! -f "$FRPS_TEMPLATE" ]; then
		echo "Template file not found: $FRPS_TEMPLATE"
		exit 1
	fi

	if [ ! -f "$FRPC_TEMPLATE" ]; then
                echo "Template file not found: $FRPC_TEMPLATE"
                exit 1
        fi

	if [ ! -f "$FRPS_OUTPUT" ]; then
                echo "No existing FRPS config. Creating FRPS and FRPC..."
		sed -e "s/{{BIND_PORT}}/$BIND_PORT/g" \
                -e "s/{{DASHBOARD_PWD}}/$DASHBOARD_PWD/g" \
                -e "s/{{TOKEN}}/$TOKEN/g" \
                $FRPS_TEMPLATE > $FRPS_OUTPUT

		sed -e "s/{{BIND_PORT}}/$BIND_PORT/g" \
                -e "s/{{DASHBOARD_PWD}}/$DASHBOARD_PWD/g" \
                -e "s/{{TOKEN}}/$TOKEN/g" \
                $FRPC_TEMPLATE > $FRPC_OUTPUT
        	
		echo "Setting up port..."
		sudo ufw allow $BIND_PORT/tcp
        	sudo ufw reload
        	sudo ufw status
	fi
	
	if [ ! -f "$DOCKER_OUTPUT" ]; then
                cp $DOCKER_TEMPLATE $DOCKER_OUTPUT
        fi
	sudo docker compose -f $DOCKER_OUTPUT up -d
}

while true; do
    show_menu
    read -p "Enter your choice [1-3]: " choice
    case "$choice" in
        1) echo "You chose Option 1";;
        2) setup_docker;;
	3) echo "v2ray";;
	4) setup_frps;;
        9) echo "Exiting..."; exit 0;;
        *) echo "Invalid option, try again.";;
    esac
done
