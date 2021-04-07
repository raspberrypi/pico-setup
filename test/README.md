# Testing pico-setup

The tests validate that `pico_setup.sh` _seems_ to setup your system correctly. It can be fooled. It does not test that the SDK or tools themselves work correctly, just that the setup script did its thing.

To execute the tests, first run `pico_setup.sh` from wherever you want to install the pico dev environment:

```shell
./pico_setup.sh
```

Logout and back in, so that your shell will pick up its environment variables. Then run the test from the same location as you ran `pico_setup.sh`:

```shell
./test/test
```

## What to test

### Platform support

We can test platform support by getting the platforms and verifying the script on each. The general process is:

1. Start from a fresh OS image.
1. Do any necessary setup.
1.1. On Raspberry Pi OS, you'll need to start the SSH service if necessary: `sudo /sbin/service ssh start`
1.1. On EC2, you'll need to set a password: `sudo -i passwd $USER`
1. Push the contents of the pico-setup repo from your dev host: `scp -r ~/git/raspberrypi/pico-setup/ pi@${TESTING_HOST}:`
1. SSH to the test host and execute the setup: `ssh pi@${TESTING_HOST} pico-setup/pico_setup.sh`
1. Logout to pick up env variables and test the setup: `ssh pi@${TESTING_HOST} pico-setup/test/test`

For all tests on Raspberry Pi computers, start with a pristine image written by Raspberry Pi Imager. The focus is on more recent hardware such as Raspberry Pi 4, but this installer's dependencies are more about software than hardware, so it should work with any version of the hardware.

The tests on non-Raspberry Pi computers can be executed on EC2 instances. The recommended EC2 instance sizes cost pennies/hour, except for mac1. mac1 costs 1.083 USD/hour in us-west-2, and requires dedicated host with minimum charge of 24 hours. You can launch and terminate instances all day on that dedicated host without cost, other than the hour it takes to clean up a terminated instance and launch a new one.

Notes on EC2:

* For the Linux x86_64 tests, t3.micro with standard 8 GiB EBS volume are sufficient.
* For the AArch64 tests, t4g.micro with standard 8 GiB EBS volume are sufficient.
* For the Windows Subsystem for Linux tests, t3.large with standard 30 GiB EBS volume are sufficient.
* For the official Ubuntu AMIs from Canonical, the default username is `ubuntu`.
* For the official Debian AMIs from Debian, the default username is `admin`.
* For the macOS and Windows AMIs from Amazon, the default username is `ec2-user`.

#### Summary

TODO: update this
|                               | Raspberry Pi | x86_64 | AArch64 |
|-|-|-|-|
| Raspberry Pi OS (32-bit)      | ✅ | Not tested | Not tested |
| Raspberry Pi OS (64-bit)      | ✅ | Not tested | Not tested |
| Raspberry Pi OS Lite (32-bit) | ✅ | Not tested | Not tested |
| Ubuntu Desktop (64-bit)       | ?  | ✅ [EC2](https://aws.amazon.com/marketplace/pp/B08LQMCZGC) | ✅ [EC2](https://aws.amazon.com/marketplace/pp/B08LQMCZGC) |
| Ubuntu Server (32-bit)        | ✅ | ? | ? |
| Debian 10 (Buster)            | ✅ | ? | ? |
| macOS 11 Big Sur              | -  | ✅ | ✅ |
| Ubuntu on WSL                 | -  | ✅ | - |
| Debian on WSL                 | -  | ✅ | - |

#### Links to EC2 for convenience

TODO: update this

|                               | x86_64 | AArch64 |
|-|-|-|-|
| Ubuntu Desktop (64-bit)       | [EC2](https://aws.amazon.com/marketplace/pp/B08LQMCZGC) | [EC2](https://aws.amazon.com/marketplace/pp/B08LQMCZGC) |
| Ubuntu Server (32-bit)        |
| Debian 10 (Buster)            | [EC2](https://aws.amazon.com/marketplace/pp/B0859NK4HC) | [EC2](https://aws.amazon.com/marketplace/pp/B0859NK4HC) |
| macOS 11 Big Sur              |
| Windows Subsustem for Linux   |

#### Windows Subsystem for Linux

Install WSL according to https://docs.microsoft.com/en-us/windows/wsl/install-on-server.

Get your Linux distro here: https://docs.microsoft.com/en-us/windows/wsl/install-manual#downloading-distributions

The Debian build apparently doesn't contain wget:

```shell
sudo apt update
sudo apt install -y wget
```

In the Linux shell:

```shell
wget https://raw.githubusercontent.com/raspberrypi/pico-setup/master/pico_setup.sh
chmod +x pico_setup.sh
./pico_setup.sh
```

## Scenarios

Here are some scenarios worth testing:

* Shells: bash, zsh. It should be enough to switch shells and rerun the installer and test scripts. You don't have to wipe the SD card/disk. Note that bash is default on Raspberry Pi OS and most other Linux distros. On macOS, the default is zsh.
* .profile or .zprofile does/doesn't end in newline
* PWD containing space. The installer script seems to handle it but an OpenOCD submodule, jimctl, doesn't. I think that jimctl is an alternative to picoprobe, so maybe we shouldn't try to build (or init) it at all. Or maybe we could do everyone a favor and send them a PR fixing it.
