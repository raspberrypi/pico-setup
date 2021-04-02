# Raspberry Pi Pico Setup

Raspberry Pi Pico Setup provides a script for installing the Pico SDK and toolchain.

# How-To

Download and run `pico_setup.sh`:
```shell
wget https://raw.githubusercontent.com/raspberrypi/pico-setup/master/pico_setup.sh
chmod +x pico_setup
./pico_setup
```
The script uses sudo, so you may need to enter your password.

After the script is complete, reboot to ensure that all changes take effect, such as the UART settings and environment variables.

If you want the testing script and documentation, you can clone the git repo too.

# Support

This script works on most Debian-derived Linux distros and macOS, running on common Raspberry Pi, PC, and Mac hardware. This ***DOESN'T*** mean that all of the pico tools work properly on these platforms. It just means that this script runs and passes its own tests.

Operating systems:
* Raspberry Pi OS (32-bit)
* Debian 10 (Buster)
* Ubuntu 20.10 (Groovy)
* macOS 11 (Big Sur)
* Ubuntu 20.04 on Windows Subsystem for Linux on Windows Server 2019 Base
* Debian GNU/Linux 1.3.0.0 on Windows Subsystem for Linux on Windows Server 2019 Base

This script does not support Windows natively, only Windows Subsystem for Linux.

Hardware:
* Raspberry Pi 2/3/4/400/CM3/CM4
* PC (x86_64)
* Mac (both Intel and Apple Silicon)

Other OSes and hardware may work, but haven't been tested. Use at your own risk.

# Testing

See [test/README.md](test/README.md).
