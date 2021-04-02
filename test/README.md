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

# What to test

## Platform support
Test support for the following platforms. The general process is:
1. Start from a fresh OS image.
1. Start the SSH service if necessary: `sudo /sbin/service ssh start`
1. Push down the contents of the pico-setup repo from your dev host: `scp -r ~/git/raspberrypi/pico-setup/ pi@pi4:`
1. SSH to the test host and execute the setup: `ssh pi@pi4 pico-setup/pico_setup.sh`
1. Logout to pick up env variables and test the setup: `ssh pi@pi4 pico-setup/test/test`

### Raspberry Pi OS (32-bit) on Raspberry Pi 4B
This is the baseline platform, what most users will have.

Write fresh SD card with Raspberry Pi Imager.

### Raspberry Pi OS (64-bit) on Raspberry Pi 4B
If all of the dependencies (APT repo, etc) are in good shape, this should work the same as the 32-bit OS, since we don't do anything explicitly for one or the other.

Write fresh SD card with Raspberry Pi Imager.

### Raspberry Pi OS Lite (32-bit) on Raspberry Pi 4B
Should be the same as the full OS, but doesn't install Visual Studio Code because there's no XWindows.

Write fresh SD card with Raspberry Pi Imager.

### Ubuntu Desktop 20.10 (64-bit) on Raspberry Pi 4B
Not yet tested.

Less common. Should work a lot like Raspberry Pi OS, but with a couple different package dependencies.

Write fresh SD card with Raspberry Pi Imager.

### Ubuntu Server 20.10 (32-bit) on Raspberry Pi 4B
Less common. Should work a lot like Raspberry Pi OS, but with a couple different package dependencies.

Write fresh SD card with Raspberry Pi Imager.

### Debian 10 (Buster) on Raspberry Pi 4B
Less common. Should work a lot like Raspberry Pi OS, but with a couple different package dependencies.

Write fresh SD card with Raspberry Pi Imager.

### macOS Big Sur on Mac mini Intel
Can be rented on EC2, but not as cheaply as the other platforms. You have to get a dedicated host, which currently costs $1.083/hour in us-west-2, with a minimum of 24 hours. You can launch and terminate instances all day on that dedicated host without extra cost, which is good for testing installers. Comes with Homebrew installed, which is nice.

Default user is `ec2-user`. You will have to use sudo to set the user's password:
```shell
sudo -i
passwd ec2-user
```

### Raspberry Pi Desktop on x86_64
Not yet tested.

### Ubuntu 20.10 on x86_64
Can be rented on [EC2](https://aws.amazon.com/marketplace/pp/B08LQMCZGC?ref_=beagle&applicationId=AWS-Marketplace-Console) for pennies/hour. Recommend t3.micro with 8 GiB EBS volume. Default user is `ubuntu`. You will have to use sudo to set the user's password:
```shell
sudo -i
passwd ubuntu
```

### Debian 10 (Buster) on x86_64
Can be rented on [EC2](https://aws.amazon.com/marketplace/pp/B0859NK4HC?ref_=aws-mp-console-subscription-detail) for pennies/hour. Recommend t3.micro with 8 GiB EBS volume. Default user is `admin`. You will have to use sudo to set the user's password:
```shell
sudo -i
passwd admin
```

### Ubuntu 20.10 on Graviton2
Can be rented on [EC2](https://aws.amazon.com/marketplace/pp/B08LQMCZGC?ref_=beagle&applicationId=AWS-Marketplace-Console) for pennies/hour. Recommend t4g.micro with 8 GiB EBS volume. Default user is `ubuntu`. You will have to use sudo to set the user's password:
```shell
sudo -i
passwd ubuntu
```

### Debian 10 (Buster) on Graviton2
Can be rented on [EC2](https://aws.amazon.com/marketplace/pp/B0859NK4HC?ref_=aws-mp-console-subscription-detail) for pennies/hour. Recommend t4g.micro with 8 GiB EBS volume. Default user is `admin`. You will have to use sudo to set the user's password:
```shell
sudo -i
passwd admin
```

### Windows Server 2016 Base on x86_64
Not yet tested. See https://aws.amazon.com/marketplace/server/procurement?productId=13c2dbc9-57fc-4958-922e-a1ba7e223b0d.

### Ubuntu 20.04 on WSL1 on Windows Server 2019 Base on x86_64
Can be rented on [EC2](https://aws.amazon.com/marketplace/server/procurement?productId=ef297a90-3ad0-4674-83b4-7f0ec07c39bb) for pennies/hour. Recommend t3.large. Default user is `ec2-user`. Connect with Microsoft Remote Desktop.

Install WSL according to https://docs.microsoft.com/en-us/windows/wsl/install-on-server. Install Ubuntu for WSL

In the Linux shell:
```shell
wget https://raw.githubusercontent.com/raspberrypi/pico-setup/master/pico_setup.sh
chmod +x pico_setup.sh
./pico_setup.sh
```

### Debian GNU/Linux 1.3.0.0 on WSL1 on Windows Server 2019 Base on x86_64
Similar instructions as Ubuntu, but using the Debian WSL package and you'll have to explicitly install wget:
```shell
sudo apt update
sudo apt install -y wget
```

Currently fails due to lack of python3.

## Scenarios
Test some scenarios:
* Shells: bash, zsh. It should be enough to switch shells and rerun the installer and test. You don't have to wipe the SD card/disk.
* .profile or .zprofile doesn't end in newline
* PWD containing space. The script seems to handle it but a OpenOCD submodule, jimctl, doesn't.
