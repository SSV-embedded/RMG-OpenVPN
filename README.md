# RMG-OpenVPN
Small OpenVPN server in a Docker container for development and testing.

**IMPORTANT!**

**The proposed setup shall be used for evaluation purposes only and is NOT RECOMMENDED FOR PRODUCTION!
All required secrets are generated on the OpenVPN server Docker container and copied to all VPN clients. This implies that a security breach on the VPN server compromises all deployed secrets.**

![rmg941c_vpn_eval](https://user-images.githubusercontent.com/85748650/126659766-daf4a8bf-6645-461c-9c53-0a4341bb3f72.png)

To keep things easy, we tuned down the security a bit and **did not set up any kind of firewall**. That means that each VPN client has full access to all other VPN clients. In the "real world", access between gateways should be more restricted.

## Linux Server
To install and run the Docker container, an appropriate server is required. You can set up your own server or rent a server from many Internet service providers.

**The server must match the following specifications:**

* Operating system **Linux Debian 10**
* Access via **SSH**
* At least **3 GB** of storage (for Linux, Docker runtime etc.)

## Install Docker Runtime on Linux Server
Establish an SSH connection with a **terminal program like PuTTY** (https://www.puttygen.com) between your PC and the Linux server.

Enter the following commands to install the Docker runtime:

      sudo apt update
      sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common
      curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
      sudo apt-key fingerprint 0EBFCD88
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
      sudo apt update
      sudo apt install docker-ce

More information on how to install Docker on a Debian Linux system:
https://www.linuxfordevices.com/tutorials/debian/install-docker-on-debian  


## Download and Run the Docker Container

### Run the Docker Container on a Public Server

      sudo docker run -d --rm --cap-add=NET_ADMIN \
        -p 1194:1194 \
        -v openvpn-etc-vol:/etc/openvpn \
        --name=vpn-server ssvembeddedde/ssv-openvpn-eval:latest &

### Run the Docker Container on a Local Server
If the server and the gateway run in a local network, or the server's public IP address is not automatically detected, then use the environment option `VPN_INTERNET_IP` to define the server's public IP address.

If the server's public port is "NATed" and changed and/or not the default port 1194, then use the environment option `VPN_INTERNET_PORT` to manually define the server's public port. For example:

      sudo docker run -d --rm --cap-add=NET_ADMIN \
          -p 1701:1194 \
          -v openvpn-etc-vol:/etc/openvpn \
          -e VPN_INTERNET_PORT="1701" \
          -e VPN_INTERNET_IP="192.168.33.1" \
          --name=vpn-server ssvembeddedde/ssv-openvpn-eval:latest &

In this example the external port 1701 is used and redirected to the internal Docker port 1194. The local IP address where the Docker host runs is 192.168.33.1 in the local network.

[More available options are listed at the end of this document.](#options-for-the-docker-container)

### Check the Running Docker Container

      sudo docker ps

This command should print an output like this:

      CONTAINER ID  IMAGE                                  COMMAND    CREATED             STATUS             PORTS                                      NAMES
      07d0ed720ad6  ssvembeddedde/ssv-openvpn-eval:latest  "vpn-cmd"  About a minute ago  Up About a minute  0.0.0.0:1194->1194/tcp, :::1194->1194/tcp  vpn-server

Display the **system log** of the running Docker container.
      
      sudo docker logs -f vpn-server

Wait for the message **Initialization Sequence Completed** and stop the logging with the key combination **CTRL-C**.

## Create and Download the VPN Client Configuration
### Create the VPN Configuration
Each VPN client needs a VPN configuration file to be able to access the VPN. In our example we create two configuration files: one for your development PC and one for the gateway.

      sudo docker cp vpn-server:/etc/openvpn/client/client-1.ovpn .
      sudo docker cp vpn-server:/etc/openvpn/client/client-2.ovpn .

If you get an error like:

      Error: No such container:path: vpn-server:/etc/openvpn/client/client-1.ovpn

Then please wait some more minutes, because creating the PKI (Public Key Infrastructure) takes some time.

### Download and Save the VPN Configuration
Display the configuration file in the terminal program.

      cat client-1.ovpn

Copy and paste the content of the terminal program into a text editor. With PuTTY you can use the command *Copy all to clipboard* from the context menu.

In the text editor remove all lines before this part:

      ### Start OF VPN CONFIG FILE ###

and after this part:

      ### END OF VPN CONFIG FILE ###

Then save this text file under the name **client-1.ovpn**.

Now do the same for **client-2.ovpn**.

### Import the VPN Configuration into the Development PC
1. Install the OpenVPN client from https://openvpn.net/vpn-client/
2. Run the OpenVPN client and click on the icon in the system tray.
3. Click in the menu on **Import Profile**.
4. Choose the option **File** and select the file **client-1.ovpn**.
5. Click on the button **Connect**.

![openvpn_connect_steps](https://user-images.githubusercontent.com/85748650/126323217-46cc220d-f71b-4080-9483-a7d178fedd83.png)

### Import the VPN Configuration into the SSV Gateway
**For information on importing the VPN configuration into your SSV gateway and connecting with the OpenVPN server, please refer to its first steps manual.**

### Check the VPN Connection
Display the status of all connected VPN clients on the server.

      sudo docker exec vpn-server vpn-cmd status

Open the VPN IP address of your SSV gateway in a browser. Typically the VPN client-1 has the VPN IP **10.126.0.6**, and the VPN client-2 has the VPN IP **10.126.0.10**. So if your SSV gateway is the VPN client-2 please open this URL:

      http://10.126.0.10:7777/

If the VPN connection works, you should see the gateway's login screen.

### Create more VPN Clients
Execute the VPN commands **new** and **get** to create more VPN client configurations.

      sudo docker exec vpn-server vpn-cmd new
      sudo docker exec vpn-server vpn-cmd get

Create VPN client configurations with a specific name:

      sudo docker exec vpn-server vpn-cmd new client-gateway
      sudo docker exec vpn-server vpn-cmd get client-gateway

## Stop and Remove the OpenVPN Docker Container
Stop the running container.

      sudo docker container stop vpn-server

Remove the container from the server.

      sudo docker image rm ssvembeddedde/ssv-openvpn-eval
      sudo docker image prune -f
      sudo docker volume prune -f

## Development

### Options for the Docker Container
This default option can only be overwritten when the Docker container is started for the first time.

      VPN_KEY_NAME="ssv-openvpn-eval"

These two options can be used to create new certificates and VPN client configurations. Leave the `VPN_INTERNET_IP` option blank to automatically detect and use the current public IP address of the server.

      VPN_INTERNET_PORT="1194"
      VPN_INTERNET_IP=""

### Build and Run the Docker Container from GitHub
Download the container source file from Github.

      cd $HOME
      curl -fsSL https://github.com/SSV-embedded/RMG-OpenVPN/archive/refs/heads/main.tar.gz >RMG-OpenVPN-main.tgz
      tar -xzf RMG-OpenVPN-main.tgz
      cd RMG-OpenVPN-main

Build the container image.

      sudo docker build -t ssv-openvpn-eval:latest .

Run the container with defaults.

      sudo docker run -d --rm --cap-add=NET_ADMIN \
        -p 1194:1194 \
        -v openvpn-etc-vol:/etc/openvpn \
        --name=vpn-server ssv-openvpn-eval &
