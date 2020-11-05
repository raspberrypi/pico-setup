#!/bin/bash

# Exit on error
set -e

if grep -q BCM2835 /proc/cpuinfo; then
    echo "Running on a Raspberry Pi"
else
    echo "Not running on a Raspberry Pi. Use at your own risk!"
fi

# Where will the output go?
OUTDIR="$(pwd)/pico"

# Install dependencies
GIT_DEPS="git"
SDK_DEPS="cmake gcc-arm-none-eabi gcc g++"
OPENOCD_DEPS="gdb-multiarch automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev"
# Wget to download the deb
VSCODE_DEPS="wget"

# Build full list of dependencies
DEPS="$GIT_DEPS $SDK_DEPS"

if [[ "$SKIP_OPENOCD" == 1 ]]; then
    echo "Skipping OpenOCD (debug support)"
else
    DEPS="$DEPS $OPENOCD_DEPS"
fi

if [[ "$SKIP_VSCODE" == 1 ]]; then
    echo "Skipping VSCODE"
else
    DEPS="$DEPS $VSCODE_DEPS"
fi

echo "Installing Dependencies"
sudo apt update
sudo apt install -y $DEPS

echo "Creating $OUTDIR"
# Create pico directory to put everything in
mkdir -p $OUTDIR
cd $OUTDIR

# Clone SDK and Examples
SDK_BRANCH="pre_release"
SDK_REPO="git@github.com:raspberrypi/pico-sdk.git"
EXAMPLES_BRANCH="pre_release"
EXAMPLES_REPO="git@github.com:raspberrypi/pico-examples.git"
# Define SDK paths
export PICO_SDK_PATH="$OUTDIR/pico-sdk"
export PICO_EXAMPLES_PATH="$OUTDIR/pico-examples"

if [ -d $PICO_SDK_PATH ]; then
    echo "pico-sdk already exists so skipping"
else
    git clone -b $SDK_BRANCH $SDK_REPO

    # Init TinyUSB
    cd $PICO_SDK_PATH
    git submodule init
    git submodule update
fi

cd $OUTDIR

if [ -d $PICO_EXAMPLES_PATH ]; then
    echo "pico-examples already exists so skipping"
else
    git clone -b $EXAMPLES_BRANCH $EXAMPLES_REPO

    # Build a couple of examples
    cd "$OUTDIR/pico-examples"
    mkdir build
    cd build
    cmake ../ -DCMAKE_BUILD_TYPE=Debug

    for e in blink hello_world
    do
        echo "Building $e"
        cd $e
        make -j4
        cd ..
    done
fi

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
    # Should we include picoprobe support (which is a Pico acting as a debugger for another Pico)
    INCLUDE_PICOPROBE=1
    OPENOCD_BRANCH="rp2040"
    OPENOCD_CONFIGURE_ARGS="--enable-ftdi --enable-sysfsgpio --enable-bcm2835gpio"
    if [[ "$INCLUDE_PICOPROBE" == 1 ]]; then
        OPENOCD_BRANCH="picoprobe"
        OPENOCD_CONFIGURE_ARGS="$OPENOCD_CONFIGURE_ARGS --enable-picoprobe"
    fi

    git clone git@github.com:raspberrypi/openocd.git -b $OPENOCD_BRANCH --depth=1
    cd openocd
    ./bootstrap
    ./configure $OPENOCD_CONFIGURE_ARGS
    make -j4
    sudo make install
fi

# Liam needed to install these to get it working
EXTRA_VSCODE_DEPS="libx11-xcb1 libxcb-dri3-0 libdrm2 libgbm1"
if [[ "$SKIP_VSCODE" == 1 ]]; then
    echo "Won't include VSCODE"
else
    if [ -f vscode.deb ]; then
        echo "Skipping vscode as vscode.deb exists"
    else
        echo "Installing VSCODE"
        if uname -m | grep -q arm64; then
            VSCODE_DEB="https://aka.ms/linux-arm64-deb"
        else
            VSCODE_DEB="https://aka.ms/linux-armhf-deb"
        fi

        wget -O vscode.deb $VSCODE_DEB
        sudo apt install -y ./vscode.deb
        sudo apt install -y $EXTRA_VSCODE_DEPS

        # Get extensions
        code --install-extension marus25.cortex-debug
        code --install-extension ms-vscode.cmake-tools
        code --install-extension ms-vscode.cpptools
    fi
fi

# Enable UART
if [[ "$SKIP_UART" == 1 ]]; then
    echo "Skipping uart configuration"
else
    echo "Disabling Linux serial console (UART) so we can use it for pico"
    sudo raspi-config nonint do_serial 0
    echo "You must run sudo reboot to finish UART setup"
fi

