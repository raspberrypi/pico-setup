# Pico-series microcontroller Command Line Setup

This script gives you an easy way to setup your Raspberry Pi to be able to build and run programs on your Pico-series microcontroller from the command line. Compatibility with any systems not running Raspberry Pi OS or Raspberry Pi OS Lite is not guaranteed or maintained.

To download & run this script, you can use the following commands:
```bash
wget https://raw.githubusercontent.com/raspberrypi/pico-setup/master/pico_setup.sh
chmod +x pico_setup.sh
./pico_setup.sh
```

For manual command line setup instructions for other operating systems, see [Basic Setup on Other Operating Systems](#basic-setup-on-other-operating-systems)

If you want to use a GUI instead of the command line, then see the [pico-vscode](https://github.com/raspberrypi/pico-vscode) extension instead of this script - this supports 64-bit Windows, MacOS, Raspberry Pi OS, and most common Linux distros. This is documented in the [Getting Started Guide](https://datasheets.raspberrypi.com/pico/getting-started-with-pico.pdf).

## Compiling and running an example

After running the setup script, you'll want to run an example to check everything's working. First go into pico-examples:
```bash
cd pico/pico-examples
```

Depending on the board you're using (eg pico2), replace `build_pico` with the relevant build directory (eg `build_pico2`) in the following commands.

> If you're not using one of the default boards (pico, pico_w, pico2, or pico2_w), you'll need to create a new build directory for your board - you can do this with this command (replace both instances of `$board` with the board you are using):
> ```
> cmake -S . -B build_$board -GNinja -DPICO_BOARD=$board -DCMAKE_BUILD_TYPE=Debug
> ```

To build the blink example, run the following command:
```bash
cmake --build build_pico --target blink
```
This builds the specified target `blink` in the build folder `build_pico` - it will probably display `no work to do` because `blink` was built earlier by `pico_setup.sh`

Then to run it, attach a Pico-series microcontroller in BOOTSEL mode, and run:
```bash
picotool load build_pico/blink/blink.uf2 -vx
```
This loads the file into Flash on the board, then verifies it was loaded correctly and reboots the board to execute it

You should now have a blinking LED on your board! For more info on the `picotool` command which is used to load and query binaries on the device, see its [README](https://github.com/raspberrypi/picotool?tab=readme-ov-file#readme)

## Console Input/Output

To view console output, you can either connect the UART output to a [Debug Probe](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html#getting-started) (or similar) and use `stdio_uart` (see the hello_serial example), or you can use `stdio_usb` (see the hello_usb example).

First, build & run the example for your `stdio` choice on your Pico-series microcontroller with the same commands as before:
```bash
cmake --build build_pico --target hello_serial
picotool load build_pico/hello_world/serial/hello_serial.uf2 -vx
```

Then attach `minicom` to view the output:
```bash
minicom -b 115200 -D /dev/ttyACM0
```
The port number may be different, so also try `/dev/ttyACM1` etc - and on other OSes may be entirely different (eg `/dev/tty.usbmodem0001` on MacOS)

To exit minicom, type Ctrl+A then X

## Debugging with OpenOCD and GDB

To debug programs on the Pico-series microcontroller, you first need to attach a debugger such as the [Debug Probe](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html#getting-started). Once that's done, you can attach OpenOCD to your Pico-series microcontroller with this command (replace `rp2040.cfg` with `rp2350.cfg`, if using an RP2350-based board like a Pico 2):
```bash
openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg -c "adapter speed 5000"
```

In a separate window, you can run GDB and connect to that OpenOCD server:
```bash
gdb -ex "target extended-remote localhost:3333"
```

Then in GDB, run the following:
```console
file build_pico/blink/blink.elf
monitor reset init
load
continue
```

To exit GDB, use Ctrl+D twice. This will leave your Pico-series microcontroller in the halted state, so you will need to unplug and replug it to get it running again. To leave the device running, you can use:
```console
monitor reset run
```
before exiting to leave the Pico running the code.

### Useful GDB Commands
To configure the GDB layout, the following commands can be useful:
* `layout src` - displays the source code
* `layout split` - displays the source code and the assembly instructions
* `layout regs` - displays the current register contents

To step through code, you can use:
* `step` or `s` - step to the next line of code, and into any functions
* `next` or `n` - step to the next line of code, without stepping into functions
* `finish` or `fin` - step out of the current function

To step through assembly instructions, you can use:
* `stepi` or `si` - step to the next assembly instruction, and into any functions
* `nexti` or `ni` - step to the next assembly instruction, without stepping into functions

While stepping, you can just press enter again to repeat the previous command

To set breakpoints, use the `break` or `b` command plus the location of the breakpoint. The location can be:
* A function name - `break main`
* A line of code - `break 12`
* Either of those in a specific file - `break blink.c:48`, `break blink.c:main`
* A specific memory address - `break *0x10000ff2`

For more details on debugging with GDB, see the [GDB docs](https://sourceware.org/gdb/current/onlinedocs/gdb.html/)

## Multiple Terminals

When debugging or viewing serial output, you might want multiple programs open in different terminals, as they all need to run at the same time.

On Raspberry Pi OS Lite, you can switch between different terminals with Alt+F1,F2,F3,F4 etc.

Alternatively you can use something like `screen` or `tmux` to allow you to open new terminals and detach from them - for example using `screen`:
* `screen -S minicom` - open a new terminal called `minicom`
* Ctrl+A then D - detach from the current terminal
* `screen -r minicom` - re-attach to an existing terminal called `minicom`
* `screen -ls` - list existing terminals

For more details on `screen`, see the [screen docs](https://www.gnu.org/software/screen/manual/screen.html)

## Basic Setup on Other Operating Systems

### Prerequisites
#### Windows

If you're on Windows, it is **strongly recommended** to use [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and then follow the [Linux instructions](#linux) inside that. You should also install [usbipd](https://github.com/dorssel/usbipd-win) to access USB devices inside WSL2 (see the docs there for instructions).

If you're not using WSL2, then you'll need to install the following tools:
* [Arm GNU Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
    * Pick Windows -> AArch32 bare-metal target (arm-none-eabi) -> the .exe file
* [CMake](https://cmake.org/download/)
* [Microsoft Visual Studio](https://visualstudio.microsoft.com/downloads/)
    * When running the installer, select Desktop Development with C++

Then follow the [manual setup instructions](#setup-sdk--picotool). You will need to run all commands from the "Developer PowerShell for VS ..." terminal, not your usual terminal. For the first cmake configuration in each project (eg `cmake ..`), you will need to replace `-GNinja` with `-G "NMake Makefiles"`, and anything with `sudo` needs to be run as administrator. Also, you should use as short a path as possible due to path length limits on Windows.

#### MacOS

Install [Homebrew](https://brew.sh/) and run these commands
```
xcode-select --install
brew install cmake ninja
brew install --cask gcc-arm-embedded
```

Then follow the [manual setup instructions](#setup-sdk--picotool).

#### Linux

If you have `apt`, then running the [pico_setup.sh](./pico_setup.sh) script should hopefully work for you, and you won't need to do any manual setup.

If it doesn't work, or you don't have `apt`, then you can manually install the `GIT_DEPS` (`git` & `git-lfs`) and `SDK_DEPS` (`cmake`, `gcc-arm-none-eabi`, `gcc`, `g++` & `ninja-build`) from the script. You may also need to install a cross-compiled `newlib` if it isn't included in `gcc-arm-none-eabi`, such as `libnewlib-arm-none-eabi` & `libstdc++-arm-none-eabi-newlib`. Once those are installed, follow the [manual setup instructions](#setup-sdk--picotool).

### Setup SDK & Picotool

#### SDK
Run this from the path you want to store the SDK:
```bash
git clone https://github.com/raspberrypi/pico-sdk.git
git -C pico-sdk submodule update --init
```

Then set `PICO_SDK_PATH` environment variable to that path - on MacOS or Linux, just add the following to your `.zshrc` (MacOS) or `.bashrc` file:
```bash
export PICO_SDK_PATH=/path/to/pico-sdk
```
then reload your terminal window.

On Windows, from an administrator PowerShell run:
```powershell
[System.Environment]::SetEnvironmentVariable('PICO_SDK_PATH','/path/to/pico-sdk', 'Machine')
```

#### Picotool
Run this from the path you want to store picotool:
```bash
git clone https://github.com/raspberrypi/picotool.git
```

Then install libusb
* On Windows, download and extract libUSB from here https://libusb.info/ (hover over Downloads, and click Latest Windows Binaries), and set LIBUSB_ROOT environment variable to the extracted directory.
* On MacOS `brew install libusb`
* On Linux `apt install libusb-1.0-0-dev`

Then build and install picotool using these commands
```bash
cd picotool
cmake -S . -B build
cmake --build build
sudo cmake --install .
```

To use picotool without sudo on Linux, you'll also need to install the picotool udev rules from the picotool/udev folder.

For more details on building & installing picotool, see its [README](https://github.com/raspberrypi/picotool?tab=readme-ov-file#readme)

### Test it's working with pico-examples
Clone pico-examples
```bash
git clone https://github.com/raspberrypi/pico-examples.git
cd pico-examples
```

Build them all, replacing `$board` with the pico board you are using
```bash
cmake -S . -B build_$board -GNinja -DPICO_BOARD=$board -DCMAKE_BUILD_TYPE=Debug
cmake --build build_$board
```

Put your board in BOOTSEL mode and use `picotool` to load the blink example:
```bash
picotool load build_$board/blink/blink.uf2 -vx
```
You should now have a blinking LED on your board
