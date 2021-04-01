# Raspberry Pi Pico Setup

Raspberry Pi Pico Setup provides a script for installing the Pico SDK and toolchain.

# How-To

<<<<<<< HEAD
Download and run `pico_setup.sh`.
=======
Download and run `pico_setup.sh`:
```shell
wget https://raw.githubusercontent.com/raspberrypi/pico-setup/master/pico_setup.sh
chmod +x pico_setup
./pico_setup
```
The script uses sudo, so you may need to enter your password.

After the script is complete, reboot to ensure that all changes take effect, such as the UART settings and environment variables.
>>>>>>> 4f2c6f4... Major rewrite. Added support for macOS, Debian, Ubuntu. Added test/validation script.

If you want the testing script and documentation, you can clone the git repo too.

# Support

Operating systems:
* Raspberry Pi OS (32-bit)
* Debian 10 (Buster)
* Ubuntu 20.10 (Groovy)
* macOS 11 (Big Sur)

Hardware:
<<<<<<< HEAD
* Raspberry Pi 2/3/4/400
* PC (x86_64)
* Mac (both Intel and Apple Silicon)

Other versions may work, but haven't been tested. Use at your own risk.

# Testing

See [test/README.md](test/README.md)
=======
* Raspberry Pi 2/3/4/400/CM3/CM4
* PC (x86_64)
* Mac (both Intel and Apple Silicon)

Other OSes and hardware may work, but haven't been tested. Use at your own risk.

# Testing

See [test/README.md](test/README.md).
>>>>>>> 4f2c6f4... Major rewrite. Added support for macOS, Debian, Ubuntu. Added test/validation script.
