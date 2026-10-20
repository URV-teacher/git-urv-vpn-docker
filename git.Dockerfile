# git with the helpers of the BMDE to run git commands through SSH with password (git.exp). The installation is done by
# the scripts in scripts/, the same ones used to install them in a host (see README.md).
# Base image of the BMDE images (docker-bake.hcl of bmde replaces this stage by the base image being built)
FROM aleixmt/bmde-base:latest AS bmde-base

FROM bmde-base

RUN --mount=type=bind,target=/component \
    /component/scripts/install_ssh.sh \
    && /component/scripts/install_git.sh \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 git-entrypoint.sh /entrypoint.sh

RUN useradd --create-home --uid 1000 --shell /bin/bash app
USER app
WORKDIR /home/app

ENTRYPOINT ["/entrypoint.sh"]
