# File:       dockerfile
# Project:    Simple openvpn Server as remote access in a docker container
# Maintainer: ssv(at)ssv-embedded.de
# Build-ID:   8602

FROM alpine:latest
RUN apk add openvpn easy-rsa wget

COPY DOCKER /

# Add volumes to allow persistence
VOLUME /etc/openvpn

# Default settings for certificates. Can be overwritten as eniroment argument at first start.
ENV VPN_PKI_NAME="ssv-openvpn-eval"

# Exported ports
EXPOSE 1194/tcp

# Start command
CMD ["vpn-cmd"]
