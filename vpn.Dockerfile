# openfortivpn with the helper of the BMDE to connect to the VPN of the URV (connect_vpn.sh). The installation is done by
# the scripts in src/, the same ones used to install them in a host (see README.md).
# Base image of the BMDE images (docker-bake.hcl of bmde replaces this stage by the base image being built)
FROM aleixmt/bmde-base:latest AS bmde-base

FROM bmde-base

RUN --mount=type=bind,target=/component \
    /component/src/install_vpn.sh \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 src/vpn-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
