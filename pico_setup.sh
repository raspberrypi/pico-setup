#!/usr/bin/env bash

# Phase 0: Preflight check
# Verify baseline dependencies

# Phase 1: Setup dev environment
# Install the software packages from APT or Homebrew
# Create a directory called pico
# Download the pico-sdk repository and submodules
# Define env variables: PICO_SDK_PATH
# On Raspberry Pi only: configure the UART for use with Raspberry Pi Pico

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
# Trying to use an non-existent variable is an error
set -u

# Number of cores when running make
JNUM=4

# Where will the output go?
if printenv TARGET_DIR; then
    echo "Using target dir from \$TARGET_DIR: ${TARGET_DIR}"
else
    TARGET_DIR="$(pwd)/pico"
    echo "Using target dir: ${TARGET_DIR}"
fi


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
    # Preflight check
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

install_dev_env_deps_linux() {
    # Install development environment dependencies for Linux

    DEPS="python3 git cmake gcc-arm-none-eabi build-essential gdb-multiarch automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev minicom pkg-config"
    if debian || ubuntu; then
        DEPS="${DEPS} libstdc++-arm-none-eabi-newlib"
    fi
    sudo apt install -y ${DEPS}
}

brew_install_idempotent() {
    # For some reason, brew install is not idempotent. This function succeeds even when the package is already installed.
    brew list ${*} || brew install ${*}
    return ${?}
}

install_dev_env_deps_mac() {
    # Install development environment dependencies for mac

    brew_install_idempotent git cmake pkg-config libtool automake libusb wget pkg-config gcc texinfo minicom ArmMbed/homebrew-formulae/arm-none-eabi-gcc
}

create_working_dir() {
    # Creates ./pico directory if necessary

    mkdir -p "${TARGET_DIR}"
}

clone_raspberrypi_repo() {
    # Clones the given repo name from GitHub and inits any submodules
    # $1 should be the full name of the repo, ex: pico-sdk
    # $2 should be the branch name. Defaults to master.
    # all other args are passed to git clone
    REPO_NAME="${1}"
    if shift && [ ${#} -gt 0 ]; then
        BRANCH="${1}"
        # Can't just say `shift` because `set -e` will think it's an error and terminate the script.
        shift || true
    else
        BRANCH=master
    fi

    # Save the working directory
    pushd "${TARGET_DIR}" >> /dev/null

    REPO_URL="https://github.com/raspberrypi/${REPO_NAME}.git"
    DEST="${TARGET_DIR}/${REPO_NAME}"

    if [ -d "${DEST}" ]; then
        echo "Not cloning ${DEST} because it already exists. If you really want to start over, delete it: rm -rf ${DEST}"
    else
        echo "Cloning ${REPO_URL}"
        if [ ${#} -gt 0 ]; then
            git clone -b "${BRANCH}" "${REPO_URL}" ${*}
        else
            git clone -b "${BRANCH}" "${REPO_URL}"
        fi

        # Any submodules
        cd "${DEST}"
        git submodule update --init
    fi

    # Restore working directory
    popd >> /dev/null
}

set_env() {
    # Permanently sets an environment variable by adding it to the current user's profile script
    # $1 should be in the form of FOO=foo
    EXPR="${1}"

    # detect appropriate file for setting env vars
    if echo "${SHELL}" | grep -q zsh; then
        # zsh detected
        FILE=~/.zprofile
    else
        # sh, bash and others
        FILE=~/.profile
    fi

    # ensure that appends go to a new line
    if [ -f "${FILE}" ]; then
        if ! ( tail -n 1 "${FILE}" | grep -q "^$" ); then
            # FILE exists but has no trailing newline. Adding newline.
            echo >> "${FILE}"
        fi
    fi

    # set for now
    export "${EXPR}"
    
    # set for later
    if ! grep -q "^export ${EXPR}$" "${FILE}"; then
        echo "Setting env variable ${EXPR} in ${FILE}"
        echo "export \"${EXPR}\"" >> "${FILE}"
    fi
}

setup_sdk() {
    # Download the SDK
    clone_raspberrypi_repo pico-sdk

    # Set env var PICO_SDK_PATH
    set_env "PICO_SDK_PATH=${TARGET_DIR}/pico-sdk"
}

enable_uart() {
    # Enable UART
    echo "Disabling Linux serial console (UART) so we can use it for pico"
    sudo raspi-config nonint do_serial 2
    echo "You must run sudo reboot to finish UART setup"
}

phase_1() {
    # Setup minimum dev environment
    echo "Entering phase 1: Setup minimum dev environment"

    if mac; then
        install_dev_env_deps_mac
    else
        install_dev_env_deps_linux
    fi

    create_working_dir
    setup_sdk

    if raspberry_pi && which raspi-config >> /dev/null; then
        enable_uart
    else
        echo "Not configuring UART because this is not a Raspberry Pi computer, or raspi-config is unavailable."
    fi
}

build_examples() {
    # Build a couple of examples
    echo "Building selected examples"
    
    cd "$TARGET_DIR/pico-examples"
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
        clone_raspberrypi_repo "${REPO_NAME}"
    done

    build_examples
}

setup_picotool() {
    # Downloads, builds, and installs picotool
    echo "Setting up picotool"

    cd "${TARGET_DIR}"

    clone_raspberrypi_repo picotool
    cd "${TARGET_DIR}/picotool"
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

    cd "${TARGET_DIR}"

    clone_raspberrypi_repo openocd picoprobe --depth=1
    cd "${TARGET_DIR}/openocd"
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

    cd "${TARGET_DIR}"

    clone_raspberrypi_repo picoprobe
    cd "${TARGET_DIR}/picoprobe"
    mkdir -p build
    cd build
    cmake ..
    make -j${JNUM}
}

install_vscode_linux() {
    # Install Visual Studio Code

    # VS Code is specially added to Raspberry Pi OS repos, but might not be present on Debian/Ubuntu. So we check first.
    if ! apt list code; then
        echo "It appears that your APT repos do not offer Visual Studio Code. Skipping."
        return
    fi

    echo "Installing Visual Studio Code"

    sudo apt install -y code

    # Get extensions
    code --install-extension marus25.cortex-debug
    code --install-extension ms-vscode.cmake-tools
    code --install-extension ms-vscode.cpptools
}

install_vscode_mac() {
    echo "Not yet implemented: installing Visual Studio Code on macOS"
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
        if dpkg-query -s xserver-xorg >> /dev/null; then
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

    echo "Congratulations, installation is complete. :D"
}

main
