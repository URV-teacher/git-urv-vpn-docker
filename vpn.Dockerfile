# openfortivpn with the helper of the BMDE to connect to the VPN of the URV (connect_vpn.sh). The installation is done by
# the scripts in src/, the same ones used to install them in a host (see README.md).
# Base image of the BMDE images (docker-bake.hcl of bmde replaces this stage by the base image being built)
FROM aleixmt/bmde-base:latest AS bmde-base

FROM bmde-base

RUN --mount=type=bind,target=/component \
    /component/src/install_vpn.sh \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 src/vpn-entrypoint.sh /entrypoint.sh

# Healthy while the VPN works, judged from the state of openfortivpn and from the internal network (vpn_healthcheck.sh).
# The connection usually takes about 2 minutes
HEALTHCHECK --interval=5s --timeout=10s --start-period=120s --retries=12 CMD ["vpn_healthcheck.sh"]

ENTRYPOINT ["/entrypoint.sh"]
