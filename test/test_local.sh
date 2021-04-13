#!/usr/bin/env bash
#
# Executes the full test suite on the local host.
#
# WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!!
# DO NOT RUN THIS SCRIPT ON A COMPUTER YOU AREN'T WILLING TO SACRIFICE.
# Running this script may result in undesired changes to this computer, such as:
# * installation of packages you don't want
# * broken or partial installations
# * broken build outputs overwriting working ones on the root filesystem
# * leaving files and data where you don't want them
# * messing with your shell and profiles
# * deleting files and directories wherever it wants to
#
# If you really want to sacrifice this computer, run with this env variable set:
# WRECK_THIS_COMPUTER="PLEASE_I_DESERVE_IT"

echo "WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!!"
echo "DO NOT RUN THIS SCRIPT ON A COMPUTER YOU AREN'T WILLING TO SACRIFICE."
echo "Running this script may result in undesired changes to this computer, such as:"
echo "* installation of packages you don't want"
echo "* broken or partial installations"
echo "* broken build outputs overwriting working ones on the root filesystem"
echo "* leaving files and data where you don't want them"
echo "* messing with your shell and profiles"
echo "* deleting files and directories wherever it wants to"
echo

if [ "${WRECK_THIS_COMPUTER}" == "PLEASE_I_DESERVE_IT" ]; then
    env | grep "WRECK_THIS_COMPUTER"
    echo "Wrecking this computer, per request..."
    echo
    echo "Waiting five seconds..."
    sleep 5
    echo
else
    echo "If you really want to sacrifice this computer, run with this env variable set:"
    echo 'WRECK_THIS_COMPUTER="PLEASE_I_DESERVE_IT"'
    exit 1
fi

# Set this after the warning, so that the debug output doesn't confuse people
set -ex

# set the debug flag for the installer script
export DEBUG=1

# Save path to the setup script, which is above this script.
SETUP_SCRIPT_PATH="$(pwd)/$(dirname "${0}")/../pico_setup.sh"

backup() {
    FILE="${1}"
    if [ -f "${FILE}" ]; then
        cp "${FILE}" "${FILE}.$(date +"%Y%m%d-%H%M%S")"
    fi
}

setup() {
    backup ~/.profile
    backup ~/.zprofile
}

start_test() {
    # Does the standard setup for a test
    TEST_NAME="${1}"
    echo "Starting ${TEST_NAME}"

    # Cleanse and change into test dir
    TEST_DIR="/tmp/${TEST_NAME}"
    rm -rf "${TEST_DIR}" || true
    mkdir -p "${TEST_DIR}"
    pushd "${TEST_DIR}" > /dev/null

    # should always start with this unset
    unset TARGET_DIR
}

execute_and_log() {
    # Executes the given args, and captures output to a log file.
    # Outputs the variable LOG_FILE, containing the path of file.
    LOG_FILE="${TEST_DIR}/$(basename ${1}).$(date +"%Y%m%d-%H%M%S.%N").log"
    echo execute_and_log: ${*}
    echo logging to: ${LOG_FILE}
    # Appending to this file is a bit of a gamble. The nanosecond-precision name should be unique, but in case it
    # isn't, I'd rather append than lose data.
    ${*} |& tee -a ${LOG_FILE}
}

complete_test() {
    popd > /dev/null

    echo "Completed ${TEST_NAME}"
    unset TEST_NAME
}

test_with_target_dir_unset() {
    start_test test_with_target_dir_unset

    # just to be sure    
    unset TARGET_DIR

    execute_and_log "${SETUP_SCRIPT_PATH}"

    complete_test
}

test_with_target_dir_set() {
    start_test test_with_target_dir_set
    
    # Set the target dir to be something below the test dir
    export TARGET_DIR="${TEST_DIR}/target_dir"
    execute_and_log "${SETUP_SCRIPT_PATH}"
    
    # verify that at least one expected git repo exists
    git -C "${TARGET_DIR}/pico-sdk" status

    unset TARGET_DIR

    complete_test
}

test_update() {
    start_test test_update
    
    # run the first time
    execute_and_log "${SETUP_SCRIPT_PATH}"


    # run a second time, watching for the indicator that we're doing the git pull.
    execute_and_log "${SETUP_SCRIPT_PATH}"
    COUNT=$(grep -c "git .* pull --ff-only" ${LOG_FILE})
    if [ 7 -ne "${COUNT}" ]; then
        echo "Didn't see the expected number of git pulls"
        exit 1
    fi

    complete_test
}

test_with_space_in_target_dir() {
    start_test test_with_space_in_target_dir
    
    # Set the target dir to be something below the test dir
    export TARGET_DIR="${TEST_DIR}/target_dir_WITH SPACE"
    execute_and_log "${SETUP_SCRIPT_PATH}"
    
    # verify that at least one expected git repo exists
    git -C "${TARGET_DIR}/pico-sdk" status

    unset TARGET_DIR

    complete_test
}

test_with_specific_shell() {
    # Execute a test in the case that the user has a certain shell. Warning: this does not attempt to change the shell
    # back.
    # $1 must be the new shell
    NEW_SHELL="${1}"
    
    # sudo to change shell, so it won't prompt for password
    sudo chsh -s "${NEW_SHELL}" "${USER}"

    # try to verify that the user is, in fact, using the new shell:
    sudo -i -u "${USER}" printenv SHELL | grep ${NEW_SHELL}
    
    execute_and_log sudo -i -u "${USER}" "${SETUP_SCRIPT_PATH}"
}

test_with_bash_user() {
    start_test test_with_bash_user

    # Setup the expected scenario    
    rm ~/.zprofile || true
    cp /etc/skel/.profile ~

    # This is a hack so that this test works. The problem is that the method of calling the installer doesn't
    # pass the TARGET_DIR env var, so we really can't install it to anywhere in particular. It goes to the ~/pico 
    # whether you want it to or not. Setting the target dir with a command line switch should allow this to be fixed.
    TARGET_DIR="${HOME}/pico"
    # clean it out
    rm -rf "${TARGET_DIR}"

    test_with_specific_shell "$(which bash)"

    # verify the change
    test "$(tail -n 1 ~/.profile)" == "export \"PICO_SDK_PATH=${TARGET_DIR}/pico-sdk\""
    # and a non-change
    test ! -f ~/.zprofile

    complete_test
}

test_with_sh_user() {
    start_test test_with_sh_user
    
    # Setup the expected scenario    
    rm ~/.zprofile || true
    cp /etc/skel/.profile ~

    # This is a hack so that this test works. The problem is that the method of calling the installer doesn't
    # pass the TARGET_DIR env var, so we really can't install it to anywhere in particular. It goes to the ~/pico 
    # whether you want it to or not. Setting the target dir with a command line switch should allow this to be fixed.
    TARGET_DIR="${HOME}/pico"
    # clean it out
    rm -rf "${TARGET_DIR}"

    test_with_specific_shell "$(which sh)"

    # verify the change
    test "$(tail -n 1 ~/.profile)" == "export \"PICO_SDK_PATH=${TARGET_DIR}/pico-sdk\""
    # and a non-change
    test ! -f ~/.zprofile

    complete_test
}

test_with_zsh_user() {
    start_test test_with_zsh_user

    # attempt to ensure zsh is installed
    sudo apt -y install zsh
    if [ ! -x "$(which zsh)"  ]; then
        echo "Can't find zsh"
        exit 1
    fi

    # Setup the expected scenario    
    rm ~/.profile || true
    rm ~/.zprofile || true

    # This is a hack so that this test works. The problem is that the method of calling the installer doesn't
    # pass the TARGET_DIR env var, so we really can't install it to anywhere in particular. It goes to the ~/pico 
    # whether you want it to or not. Setting the target dir with a command line switch should allow this to be fixed.
    TARGET_DIR="${HOME}/pico"
    # clean it out
    rm -rf "${TARGET_DIR}"

    test_with_specific_shell "$(which zsh)"

    # verify the change
    test "$(tail -n 1 ~/.zprofile)" == "export \"PICO_SDK_PATH=${TARGET_DIR}/pico-sdk\""
    # and a non-change
    test ! -f ~/.profile

    complete_test
}

test_with_naked_tail_dot_profile() {
    start_test test_with_naked_tail_dot_profile

    # Setup the expected scenario
    echo -n "# no newline!" > ~/.profile
    xxd ~/.profile

    # This is a hack so that this test works. The problem is that the method of calling the installer doesn't
    # pass the TARGET_DIR env var, so we really can't install it to anywhere in particular. It goes to the ~/pico 
    # whether you want it to or not. Setting the target dir with a command line switch should allow this to be fixed.
    TARGET_DIR="${HOME}/pico"
    # clean it out
    rm -rf "${TARGET_DIR}"

    test_with_specific_shell "$(which bash)"

    # verify the change
    test "$(tail -n 1 ~/.profile)" == "export \"PICO_SDK_PATH=${TARGET_DIR}/pico-sdk\""

    complete_test
}

execute_all_tests() {
    # Execute all the (enabled) tests
    
    setup

    test_with_target_dir_unset
    test_with_target_dir_set
    test_update
    # Doesn't work because of jimtcl
    # test_with_space_in_target_dir
    test_with_bash_user
    test_with_sh_user
    test_with_zsh_user
    test_with_naked_tail_dot_profile
}


execute_all_tests
