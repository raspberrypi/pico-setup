#!/bin/bash

# Exit on error
set -e

if grep -q Raspberry /proc/cpuinfo; then
    echo "Running on a Raspberry Pi"
else
    echo "Not running on a Raspberry Pi. Use at your own risk!"
    SKIP_UART=1
fi

# Number of cores when running make
JNUM=4

# Where will the output go?
OUTDIR="$(pwd)/pico"

# Install dependencies
GIT_DEPS="git"
SDK_DEPS="cmake gcc-arm-none-eabi gcc g++ ninja-build"
OPENOCD_DEPS="gdb-multiarch automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev libjim-dev pkg-config libgpiod-dev"
OPENOCD_TAG="sdk-2.2.0"
UART_DEPS="minicom"

# Build full list of dependencies
DEPS="$GIT_DEPS $SDK_DEPS"

if [[ "$SKIP_OPENOCD" == 1 ]]; then
    echo "Skipping OpenOCD (debug support)"
else
    DEPS="$DEPS $OPENOCD_DEPS"
fi

echo "Installing Dependencies"
sudo apt update
sudo apt install -y $DEPS

echo "Creating $OUTDIR"
# Create pico directory to put everything in
mkdir -p $OUTDIR
cd $OUTDIR

# Clone sw repos
GITHUB_PREFIX="https://github.com/raspberrypi/"
GITHUB_SUFFIX=".git"
SDK_BRANCH="master"

for REPO in sdk examples extras playground
do
    DEST="$OUTDIR/pico-$REPO"

    if [ -d $DEST ]; then
        echo "$DEST already exists so skipping"
    else
        REPO_URL="${GITHUB_PREFIX}pico-${REPO}${GITHUB_SUFFIX}"
        echo "Cloning $REPO_URL"
        git clone -b $SDK_BRANCH $REPO_URL

        # Any submodules
        cd $DEST
        git submodule update --init
        cd $OUTDIR

        # Define PICO_SDK_PATH in ~/.bashrc
        VARNAME="PICO_${REPO^^}_PATH"
        echo "Adding $VARNAME to ~/.bashrc"
        echo "export $VARNAME=$DEST" >> ~/.bashrc
        export ${VARNAME}=$DEST
    fi
done

cd $OUTDIR

# Pick up new variables we just defined
source ~/.bashrc

# Debugprobe and picotool
for REPO in picotool debugprobe
do
    DEST="$OUTDIR/$REPO"
    REPO_URL="${GITHUB_PREFIX}${REPO}${GITHUB_SUFFIX}"
    if [[ "$REPO" == "picotool" ]]; then
      git clone -b $SDK_BRANCH $REPO_URL
    else
      git clone $REPO_URL
    fi

    # Build both
    cd $DEST
    git submodule update --init
    cmake -S . -B build -GNinja
    cmake --build build

    if [[ "$REPO" == "picotool" ]]; then
        echo "Installing picotool"
        sudo cmake --install build
    fi

    cd $OUTDIR
done

# Build blink and hello world for default boards
cd pico-examples
for board in pico pico_w pico2 pico2_w
do
    build_dir=build_$board
    cmake -S . -B $build_dir -GNinja -DPICO_BOARD=$board -DCMAKE_BUILD_TYPE=Debug
    examples="blink hello_serial hello_usb"
    echo "Building $examples for $board"
    cmake --build $build_dir --target $examples
done

cd $OUTDIR

if [ -d openocd ]; then
    echo "openocd already exists so skipping"
    SKIP_OPENOCD=1
fi

if [[ "$SKIP_OPENOCD" == 1 ]]; then
    echo "Won't build OpenOCD"
else
    # Build OpenOCD
    echo "Building OpenOCD"
    cd $OUTDIR
    OPENOCD_CONFIGURE_ARGS="--enable-ftdi --enable-sysfsgpio --enable-bcm2835gpio --disable-werror --enable-linuxgpiod"

    git clone "${GITHUB_PREFIX}openocd${GITHUB_SUFFIX}" -b ${OPENOCD_TAG} --depth=1
    cd openocd
    ./bootstrap
    ./configure $OPENOCD_CONFIGURE_ARGS
    make -j$JNUM
    sudo make install
fi

cd $OUTDIR

# Enable UART
if [[ "$SKIP_UART" == 1 ]]; then
    echo "Skipping uart configuration"
else
    sudo apt install -y $UART_DEPS
    echo "Disabling Linux serial console (UART) so we can use it for pico"

    # Enable UART hardware
    sudo raspi-config nonint do_serial_hw 0
    # Disable console over serial port
    sudo raspi-config nonint do_serial_cons 1

    echo "You must run sudo reboot to finish UART setup"
fi
