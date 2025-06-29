FROM ubuntu:20.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libappindicator3-1 \
    libayatana-appindicator3-1 \
    libatk-bridge2.0-0 \
    libatspi2.0-0 \
    libgtk-3-0 \
    libx11-xcb1 \
    libsecret-1-0 \
    libnss3-tools \
    libxss1 \
    iptables \
    ca-certificates \
    wget \
    curl \
    gnupg \
    software-properties-common \
    expect && \
    rm -rf /var/lib/apt/lists/*

# Install FortiClient
RUN wget https://filestore.fortinet.com/forticlient/downloads/forticlient_vpn_7.4.3.1736_amd64.deb && \
    dpkg -i forticlient_vpn_7.4.3.1736_amd64.deb || true && \
    apt-get install -f -y && \
    rm forticlient_vpn_7.4.3.1736_amd64.deb

COPY ./src/configure_fortivpn.exp /usr/local/bin/configure_fortivpn.exp
RUN chmod +x /usr/local/bin/configure_fortivpn.exp

COPY ./src/connect_fortivpn.exp /usr/local/bin/connect_fortivpn.exp
RUN chmod +x /usr/local/bin/connect_fortivpn.exp

# Add custom entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]