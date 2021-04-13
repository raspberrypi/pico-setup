# Raspberry Pi Pico Setup

Raspberry Pi Pico Setup provides a script for installing the Pico SDK and toolchain.

## How-To

Download and run `pico_setup.sh`:

```shell
wget https://raw.githubusercontent.com/raspberrypi/pico-setup/master/pico_setup.sh
chmod +x pico_setup.sh
./pico_setup.sh
```

The script uses sudo, so you may need to enter your password.

After the script is complete, reboot to ensure that all changes take effect, such as the UART settings and environment variables.

If you want the testing script and documentation, you can clone the git repo too.

## Support

This script works on most Debian-derived Linux distros and macOS, running on common Raspberry Pi, PC, and Mac hardware. This ***DOESN'T*** mean that all of the pico tools work properly on these platforms. It just means that this script runs and passes its own tests.

Operating systems:

* Raspberry Pi OS (32-bit)
* Debian 10 (Buster)
* Ubuntu 20.04 or later
* macOS 11 (Big Sur)
* Windows Subsystem for Linux

Hardware:

* Any model of Raspberry Pi
* PC (x86_64)
* Mac (both Intel and Apple Silicon)

Visual Studio Code may not run well on Raspberry Pi 1 and Zero because of their smaller RAM capacity, but the rest of the toolkit works fine.

Other OSes and hardware _may_ work, but haven't been tested. Use at your own risk.

## Testing

See [test/README.md](test/README.md).
