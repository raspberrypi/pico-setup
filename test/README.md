# Testing pico-setup

`pico_setup.sh` validates that it has the expected effect for your specific setup. However, the script needs to work on a variety of platforms, so we test a variety.

***Be warned: the testing script is destructive.*** It configures the system in all kinds of ways to see if the script can handle it, and makes little attempt to put things back where they were before. These tests are expected to be run on a single-use system. You start with a fresh image at the beginning, and discard it at the end.

The general testing process is:

1. Start from a fresh OS image.
1.1. On Raspberry Pi OS, you'll need to start the SSH service if necessary: `sudo /sbin/service ssh start`
1. Push the contents of the pico-setup repo from your dev host: `scp -r ~/git/raspberrypi/pico-setup/ ${TEST_USER}@${TEST_HOST}:`
1. SSH to the test host and execute the test suite: `ssh ${TEST_USER}@${TEST_HOST} "export WRECK_THIS_COMPUTER=PLEASE_I_DESERVE_IT && pico-setup/test/test_local.sh" |& tee ${TEST_HOST}.log`

The `tee` part captures all output and dumps it to a log file on the local host so you can investigate anything that went wrong. Additionally, logs for each test should be on the testing host, at `/tmp/test_*`

If the test completes successfully, it will say that it's complete and return 0. If it fails, it will return non-zero.

## Preparations

For all tests on Raspberry Pi computers, start with a pristine image written by Raspberry Pi Imager. The focus is on more recent hardware such as Raspberry Pi 4, but this installer's dependencies are more about software than hardware, so it should work with any version of the hardware.

Raspberry Pi is an ARM platform, so testing Raspberry Pi hardware technically covers ARM tests. However, the Linux distros built for Raspberry Pi hardware tend to be customized, so testing the mainline build is nonetheless relevant.

The tests on non-Raspberry Pi computers can be executed on EC2 instances. The recommended EC2 instance sizes cost pennies/hour, except for mac1. mac1 costs 1.083 USD/hour in us-west-2, and requires dedicated host with minimum charge of 24 hours. You can launch and terminate instances all day on that dedicated host without cost, other than the hour it takes to clean up a terminated instance and launch a new one.

Notes on EC2:

* For the Linux x86 tests, t3.micro with standard 8 GiB EBS volume are sufficient.
* For the ARM tests, t4g.micro with standard 8 GiB EBS volume are sufficient.
* For the Windows Subsystem for Linux tests, t3.large with standard 30 GiB EBS volume are sufficient.
* For the official Ubuntu AMIs from Canonical, the default username is `ubuntu`.
* For the official Debian AMIs from Debian, the default username is `admin`.
* For the macOS and Windows AMIs from Amazon, the default username is `ec2-user`.

## Summary

* ✅ Means this version is tested and works on this platform.
* ? Means this version hasn't been tested on this platform.
* (blank) Means this platform isn't relevant.

| | Raspberry Pi | x86 | ARM |
|-|-|-|-|
| Raspberry Pi OS  | ✅ | ? |  |
| Ubuntu 20        | ? | ✅ | ✅ |
| Debian 10        | ? | ✅ | ✅ |
| macOS 11 Big Sur |   | ? | ? |
| Ubuntu on WSL    |   | ? |   |
| Debian on WSL    |   | ? |   |

## Windows Subsystem for Linux

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
