FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    openfortivpn \
    git \
    expect \
    jq \
    time \
    wget && \
    rm -rf /var/lib/apt/lists/* && \
    git config --global advice.detachedHead false

COPY ./src/git_clone.exp /git_clone.exp
RUN chmod +x /git_clone.exp

COPY ./src/connect_vpn.sh /connect_vpn.sh
RUN chmod +x /connect_vpn.sh

COPY ./src/clone_repos.sh /clone_repos.sh
RUN chmod +x /clone_repos.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]