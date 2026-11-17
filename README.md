# modemmanager-deb

ModemManager as Debian trixie and Ubuntu 26.04 (resolute) ship it, rebuilt
with the patches the Citronics Lime boards (Fairphone 2 and 3) need for
mobile data. The packages are published in the
[Citronics APT repository](https://github.com/Citronics/deb-packages), in the
suite named after the distribution release (`trixie`, `resolute`), which the
images and the `citronics-lime-*` meta-packages configure.

## Patches

| Patch | Status | Fixes |
| --- | --- | --- |
| `0001-netlink-fix-use-after-free-on-transaction-completion` | upstream [9317cbc4](https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/commit/9317cbc4702c7d6283e42a498cd9812e19eeccf3), not yet in a release | ModemManager crashes (SIGSEGV) at every start after the first one, so the modem never stays available. |
| `0002-broadband-modem-qmi-omit-an-empty-profile-name` | Citronics, to be sent upstream | The FP2 modem rejects profile requests with an empty profile name (`DS profile error: invalid-parameter-length`), so ModemManager cannot set the LTE attach APN (initial EPS bearer). |
| `0003-bearer-properties-loosely-match-allowed-auth-methods` | Citronics, to be sent upstream | NetworkManager (1.52+) allows every authentication method for the attach APN; a QMI profile stores PAP and CHAP only, so the update was reported as failed (`Initial EPS bearer settings were not updated`), failing the connection, and identical settings were never recognized as applied, power cycling the modem at every connection. |
| `0004-shared-qmi-don-t-restart-the-network-search-for-automatic-registration` | Citronics, to be sent upstream | Connecting while the modem still searches after boot requested automatic registration; the FP2 modem restarts its network search on that request even when nothing changes, adding 75 to 140 seconds before registration. |

Without the attach APN fixes, a modem whose attach APN is another
operator's stays on 2G, or the connection fails on LTE
(`multiple-connection-to-same-pdn-not-allowed`); NetworkManager sets it from
the connection's `gsm.initial-eps-bearer-apn`.

A patch is dropped once both distributions ship a version that contains it.

## Versions

Each build is the distribution's own source package plus the patches, with
the version `<distribution version>+citronics<REVISION>`, so it replaces the
distribution's package and a newer distribution version (a security or
stable update) replaces it in turn.

## Building

CI (`.github/workflows/build.yml`) checks the distributions' modemmanager
source version daily, builds every version not yet released for armhf
(QEMU) and arm64, publishes a GitHub release per codename
(`<codename>-<version>`, with a `suites.tsv` naming each package's suite),
deletes the codename's previous release and asks deb-packages to update the
APT index. Changing `patches/` or `build.sh` needs a `REVISION` bump; the
build fails when a patch no longer applies to a distribution's version.

Locally (Docker with QEMU binfmt for armhf):

```
docker run --rm --platform linux/arm/v7 -v "$PWD:/work" ubuntu:26.04 /work/build.sh
docker run --rm --platform linux/arm/v7 -v "$PWD:/work" debian:trixie /work/build.sh
```

The packages land in `out/<codename>/`.

`distributions` lists the codenames and the container images they build in.
