# cloner
Clones Git repos from the private servers of the DEIM

./src/connect_fortivpn.exp $(cat ./secrets/VPN_PROFILE) $(cat ./secrets/VPN_PASSWORD)

 ./src/configure_fortivpn.exp $(cat ./secrets/VPN_PROFILE) $(cat ./secrets/VPN_GATEWAY) $(cat ./secrets/VPN_USER)

## Build and installation
The scripts in `src/` install git (with the helpers `git.exp`, `git_clone.exp` and `clone_repos.sh`), the SSH client
and openfortivpn (with the helper `connect_vpn.sh`), with the helpers in `/URV/bmde/git-urv-vpn/bin` and their
environment (`PATH`) in `/etc/profile.d/bmde-git-urv-vpn.sh`. The images are built with them, and they install the
same tools in an Ubuntu / Debian host too:

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
