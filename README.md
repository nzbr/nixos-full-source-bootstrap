# A Full-Source Bootstrap for NixOS

Builds a NixOS installation fully from source.
This code was created as part of [my bachelor's thesis](https://nzbr.github.io/nixos-full-source-bootstrap/thesis.pdf).\
The [presentation slides can be found here](https://nzbr.github.io/nixos-full-source-bootstrap/presentation/original/) (or the [extended version here](https://nzbr.github.io/nixos-full-source-bootstrap/presentation/extended/)).

## Structure

The bootstrap chain consists of two largely independent parts:

- The _inner bootstrap_ consists of a [nixpkgs fork](https://github.com/nzbr/nixpkgs/tree/bootstrap) that has been modified so that the pre-build bootstrap seeds ususally used by nixpkgs are replaced with a version built from the bootstrapped packages built by [Aux Foundation](https://git.auxolotl.org/auxolotl/foundation).
- The _outer bootstrap_ is a [modified fork of live-bootstrap](https://github.com/nzbr/live-bootstrap/tree/nixos) that has been extended to build a full NixOS installation from source, using the modified nixpkgs from the _inner bootstrap_.

## Usage

A computer running Linux is required to prepare the bootstrap.
All needed dependencies are included in the Nix devShell.
On a system that has Nix installed, it can be activated by running `nix develop` in the `live-bootstrap` directory.

The bootstrap itself works exclusively on 64-bit x86 based machines. It can be executed on physical hardware as well as in a QEMU-based virtual machine.

First of all, clone all submodules:
```bash
git submodule update --init --recursive
```

### QEMU

```bash
cd live-bootstrap
make BOOTSTRAP_PLATFORM=qemu BOOTSTRAP_EXTS="nix nixos" bootstrap
```

The built system can be started with 
```
make
```

Check `live-bootstrap/Makefile` for the possible configuration options

### Physical Computer

To generate the bootstrap images, run:

```bash
cd live-bootstrap
make BOOTSTRAP_PLATFORM=bare-metal BOOTSTRAP_EXTS="nix nixos" target/seed
```

Then, write `target/seed/init.img` and `target/seed/external.img` to two separate drives, using your boot media creation tool of choice.
Boot up the target system and select the `init.img` drive as the boot device.

Important: live-bootstrap expects the external disk to appear as `/dev/sdb1` in Linux. If this is not true in your setup, change this in [`rootfs.py`](./live-bootstrap/rootfs.py#L48)

#### Hardware requirements

- The `external.img` disk needs to have enough space to accomodate all needed files during the build process. I recommend at least 128GiB.
- The target computer needs to be able to boot in BIOS mode. Computers that only support UEFI are not compatible.

## Backup Sources

In the (likely) event, that some of the needed sources are no longer available, a mirror is available.
To use it, copy the replacement `sources` files from the `backup-sources` directory to the `live-bootstrap` directory like this:

```bash
cp -vr backup-sources/. live-bootstrap/
rm live-bootstrap/generate.sh
```

The included `generate.sh` script is used to generate the mirror `sources` files from the original ones.

To make sure that the bootstrap does not attempt to download the source files on-the-fly, enable the bootstrap's offline mode by adding `BOOTSTRAP_OFFLINE=1` to the `make` commandline.
