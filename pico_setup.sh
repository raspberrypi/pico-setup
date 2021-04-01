#!/usr/bin/env bash

# Phase 0: Preflight check
# Verify baseline dependencies

# Phase 1: Setup minimum dev environment
# Install the toolchain
# Create a directory called pico
# Download the pico-sdk repository and submodules
# Define env variables for repo: PICO_SDK_PATH
# Configure the Raspberry Pi UART for use with Raspberry Pi Pico

# Phase 2: Setting up tutorial repos
# Download pico-examples, pico-extras, pico-playground repositories, and submodules
# Build the blink and hello_world examples

# Phase 3: Recommended tools
# Download and build picotool (see Appendix B), and copy it to /usr/local/bin.
# Download and build picoprobe (see Appendix A) and OpenOCD
# Download and install Visual Studio Code and required extensions



# Exit on error
set -e
# Show all commands
set -x


# Number of cores when running make
JNUM=4

# Where will the output go?
WORKING_DIR="$(pwd)/pico"


linux() {
    # Returns true iff this is running on Linux
    uname | grep -q "^Linux$"
    return ${?}
}

raspbian() {
    # Returns true iff this is running on Raspbian or close derivative such as Raspberry Pi OS, but not necessarily on a Raspberry Pi computer
    grep -q '^NAME="Raspbian GNU/Linux"$' /etc/os-release
    return ${?}
}

debian() {
    # Returns true iff this is running on Debian
    grep -q '^NAME="Debian GNU/Linux"$' /etc/os-release
    return ${?}
}

ubuntu() {
    # Returns true iff this is running on Ubuntu
    grep -q '^NAME="Ubuntu"$' /etc/os-release
    return ${?}
}

mac() {
    # Returns true iff this is running on macOS and presumably Apple hardware
    uname | grep -q "^Darwin$"
    return ${?}
}

raspberry_pi() {
    # Returns true iff this is running on a Raspberry Pi computer, regardless of the OS
    if [ -f /proc/cpuinfo ]; then
        grep -q "^Model\s*: Raspberry Pi" /proc/cpuinfo
        return ${?}
    fi
    return 1
}

phase_0() {
    # Preflight the check
    # Checks the baseline dependencies. If you don't have these, this script won't work.
    echo "Entering phase 0: Preflight check"
    
    echo "Verifying sudo access"
    sudo -v

    if mac; then
        echo "Running on macOS"
        if which brew >> /dev/null; then
            echo "Found brew"
            brew update
        else
            echo -e 'This script requires Homebrew, the missing package manager for macOS. See https://docs.brew.sh/Installation. For quick install, run:\n/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'
            echo "Stopping."
            exit 1
        fi
    else
        if linux; then
            echo "Running on Linux"
        else
            echo "Platform $(uname) not recognized. Use at your own risk. Continuing as though this were Linux."
        fi

        if which apt >> /dev/null; then
            echo "Found apt"
            sudo apt update
        else
            echo 'This script requires apt, the default package manager for Debian and Debian-derived distros such as Ubuntu, and Raspberry Pi OS.'
            echo "Stopping."
            exit 1
        fi
    fi
}

install_toolchain_linux() {
    # Install toolchain for Linux

    DEPS="git cmake gcc-arm-none-eabi build-essential gdb-multiarch automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev"
    if debian || ubuntu; then
        DEPS="${DEPS} pkg-config libstdc++-arm-none-eabi-newlib"
    fi
    sudo apt install -y ${DEPS}
}

brew_install_idempotent() {
    # For some reason, brew install is not idempotent. This function succeeds even when the package is already installed.
    brew list ${*} || brew install ${*}
    return ${?}
}

install_toolchain_mac() {
    # Install dependencies for mac

    brew_install_idempotent git cmake pkg-config libtool automake libusb wget pkg-config gcc texinfo
    brew tap ArmMbed/homebrew-formulae
    brew_install_idempotent arm-none-eabi-gcc
}

create_working_dir() {
    # Creates ./pico directory if necessary

    mkdir -p "${WORKING_DIR}"
}

clone_repo() {
    # Clones the given repo name from GitHub and inits any submodules
    # $1 should be the full name of the repo, ex: pico-sdk
    # $2 should be the branch name. Defaults to master.
    # all other args are passed to git clone
    REPO_NAME="${1}"
    if shift && [ "${1}" ]; then
        BRANCH="${1}"
    else
        BRANCH=master
    fi
    if shift; then
        # $* contains more args
        true
    fi

    cd "${WORKING_DIR}"

    REPO_URL="https://github.com/raspberrypi/${REPO_NAME}.git"
    DEST="${WORKING_DIR}/${REPO_NAME}"

    if [ -d "${DEST}" ]; then
        echo "Not cloning $DEST because it already exists"
    else
        echo "Cloning $REPO_URL"
        git clone -b "$BRANCH" "$REPO_URL" ${*}

        # Any submodules
        cd "$DEST"
        git submodule update --init
    fi
}

set_envs() {
    # Permanently sets environment variables by adding them to the current user's profile script
    # arguments should be in the form of FOO=foo BAR=bar

    # detect appropriate file for setting env vars
    if echo "${SHELL}" | grep -q zsh; then
        # zsh detected
        FILE=~/.zprofile
    else
        # sh, bash and others
        FILE=~/.profile
    fi

    # ensure that appends go to a new line
    if [ -f ${FILE} ]; then
        if tail -n 1 ${FILE} | grep -q "^$"; then
            echo "${FILE} exists and has trailing newline."
        else
            echo "${FILE} exists but has no trailing newline. Adding newline."
            echo >> ${FILE}
        fi
    fi

    for EXPR in ${*}; do
        # set for now
        export "${EXPR}"
        
        # set for later
        set_env "${FILE}" "${EXPR}"
    done
}

set_env() {
    # Permanently sets one environment variable for bash
    # $1 must be the file where the env is stored
    # $2 should be in the form of VAR=value
    FILE="${1}"
    EXPR="${2}"

    if ! grep -q "^export ${EXPR}$" ${FILE}; then
        echo "Setting env variable ${EXPR} in ${FILE}"
        echo "export ${EXPR}" >> ${FILE}
    fi
}

setup_sdk() {
    # Downloads and builds the SDK
    cd "${WORKING_DIR}"

    clone_repo pico-sdk

    # Set env var PICO_SDK_PATH
    REPO_UPPER=$(echo ${REPO_NAME} | tr "[:lower:]" "[:upper:]")
    REPO_UPPER=$(echo ${REPO_UPPER} | tr "-" "_")
    set_envs "${REPO_UPPER}_PATH=$DEST"
}

enable_uart() {
    # Enable UART
    sudo apt install -y minicom
    echo "Disabling Linux serial console (UART) so we can use it for pico"
    sudo raspi-config nonint do_serial 2
    echo "You must run sudo reboot to finish UART setup"
}

phase_1() {
    # Setup minimum dev environment
    echo "Entering phase 1: Setup minimum dev environment"

    if mac; then
        install_toolchain_mac
    else
        install_toolchain_linux
    fi

    create_working_dir
    setup_sdk

    if linux && pi; then
        if [[ "$SKIP_UART" == 1 ]]; then
            echo "Skipping UART configuration"
        else
            enable_uart
        fi
    else
        echo "Not configuring UART because this is not running Raspberry Pi OS on a Raspberry Pi computer"
    fi
}

build_examples() {
    # Build a couple of examples
    echo "Building selected examples"
    
    cd "$WORKING_DIR/pico-examples"
    mkdir -p build
    cd build
    cmake ../ -DCMAKE_BUILD_TYPE=Debug

    for EXAMPLE in blink hello_world; do
        echo "Building $EXAMPLE"
        cd "$EXAMPLE"
        make -j${JNUM}
        cd ..
    done
}

phase_2() {
    # Setup tutorial repos
    echo "Entering phase 2: Setting up tutorial repos"

    for REPO_NAME in pico-examples pico-extras pico-playground; do
        clone_repo "${REPO_NAME}"
    done

    build_examples
}

setup_picotool() {
    # Downloads, builds, and installs picotool
    echo "Setting up picotool"

    cd "${WORKING_DIR}"

    clone_repo picotool
    cd "${WORKING_DIR}/picotool"
    mkdir -p build
    cd build
    cmake ../
    make -j${JNUM}

    echo "Installing picotool to /usr/local/bin/picotool"
    sudo cp picotool /usr/local/bin/
}

setup_openocd() {
    # Download, build, and install OpenOCD for picoprobe and bit-banging without picoprobe
    echo "Setting up OpenOCD"

    cd "${WORKING_DIR}"

    clone_repo openocd picoprobe --depth=1
    cd "${WORKING_DIR}/openocd"
    ./bootstrap
    OPTS="--enable-ftdi --enable-bcm2835gpio  --enable-picoprobe"
    if linux; then
        # sysfsgpio is only available on linux
        OPTS="${OPTS} --enable-sysfsgpio"
    fi
    ./configure ${OPTS}
    make -j${JNUM}
    sudo make install
}

setup_picoprobe() {
    # Download and build picoprobe. Requires that OpenOCD is already setup
    echo "Setting up picoprobe"

    cd "${WORKING_DIR}"

    clone_repo picoprobe
    cd "${WORKING_DIR}/picoprobe"
    mkdir -p build
    cd build
    cmake ..
    make -j${JNUM}
}

install_vscode_linux() {
    # Install Visual Studio Code

    # VS Code is specially added to Raspberry Pi OS repos. Need to add the right repos to make it work on Debian/Ubuntu.
    if debian || ubuntu; then
        echo "Visual Studio Code installation currently doesn't work on Debian and Ubuntu"
        return
    fi

    echo "Installing Visual Studio Code"

    cd "${WORKING_DIR}"

    sudo apt install -y code

    # Get extensions
    code --install-extension marus25.cortex-debug
    code --install-extension ms-vscode.cmake-tools
    code --install-extension ms-vscode.cpptools
}

install_vscode_mac() {
    echo "This script cannot install Visual Studio Code on macOS"
}

phase_3() {
    # Setup recommended tools
    echo "Setting up recommended tools"

    setup_picotool
    setup_openocd
    setup_picoprobe

    # Install Visual Studio Code
    if mac; then
        install_vscode_mac
    else
        if dpkg-query -s libx11-6; then
            install_vscode_linux
        else
            echo "Not installing Visual Studio Code because it looks like XWindows is not installed."
        fi
    fi
}

main() {
    phase_0
    phase_1
    phase_2
    phase_3

    echo "Congratulations, installation is complete. 😁"
}

main