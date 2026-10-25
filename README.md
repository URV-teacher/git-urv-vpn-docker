# cloner
Clones Git repos from the private servers of the DEIM

./src/connect_fortivpn.exp $(cat ./secrets/VPN_PROFILE) $(cat ./secrets/VPN_PASSWORD)

 ./src/configure_fortivpn.exp $(cat ./secrets/VPN_PROFILE) $(cat ./secrets/VPN_GATEWAY) $(cat ./secrets/VPN_USER)

## Build and installation
The scripts in `src/` install git (with the helpers `git.exp`, `git_clone.exp` and `clone_repos.sh`), the SSH client
and openfortivpn (with the helpers `connect_vpn.sh` and `vpn_healthcheck.sh`, see [VPN](#vpn)), with the helpers in
`/URV/bmde/git-urv-vpn/bin` and their environment (`PATH`) in `/etc/profile.d/bmde-git-urv-vpn.sh`. The images are
built with them, and they install the same tools in an Ubuntu / Debian host too:

```shell
src/install_ssh.sh
src/install_git.sh
src/install_vpn.sh
```

This component has no assets to download: its scripts only install packages of the system and the helpers of `src/`.

Test the installation with the `test/test_*.sh` scripts (`test_operation.sh` needs your user of the course). To build
the images:

```shell
docker build -t aleixmt/git-sshpass -f git.Dockerfile .
docker build -t aleixmt/forticlient -f vpn.Dockerfile .
```

## VPN

`connect_vpn.sh` connects to the VPN of the URV with openfortivpn, waits until it works and stays connected until it
is stopped (Ctrl+C). It works the same in a host and in a container: run it as your user, without `sudo` (only
openfortivpn needs root, and the script runs it with `sudo` when you are not root). It takes the credentials from
`/run/secrets/NAME` (Docker secrets), from the file in `$NAME_FILE` or from `$NAME`, for each of `vpn_username`,
`vpn_password`, `vpn_host`, `vpn_port`, `vpn_realm`, `vpn_cert` and, to check that the internal network works,
`vpn_test_ip` and `vpn_test_dns`:

```shell
VPN_USERNAME=... VPN_PASSWORD_FILE=~/.vpn_password VPN_HOST=... VPN_PORT=... VPN_REALM=... VPN_CERT=... connect_vpn.sh
```

The script itself writes no file of the system (openfortivpn sets the routes and the DNS of the VPN): the configuration
of openfortivpn (with the password, removed as soon as openfortivpn reads it) and its log go to `VPN_STATE_DIR`
(`$XDG_RUNTIME_DIR/bmde-vpn` by default, or `/tmp/bmde-vpn-UID`), only readable by you. `VPN_TIMEOUT` is how many
seconds it waits for the VPN to work (300 by default).

`vpn_healthcheck.sh` tells whether the VPN works (exit status 0) from the state of openfortivpn, without root and
without any file created by the connection: openfortivpn is running, its PPP interface exists and the test IP and DNS
name answer, when they are configured. `-v` prints why it does not work. It is the `HEALTHCHECK` of
`aleixmt/forticlient`.
