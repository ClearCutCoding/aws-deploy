#!/usr/bin/env bash
set -e

VAR_SCRIPT_DIR="$(dirname "$(readlink -f "$0")")" # follow symlink
VAR_RUNNING_DIR="$(pwd)"

# Following will be filled from config file
declare -A VAR_VALID_TARGETS=
VAR_VALID_IMAGES_LIST=
VAR_DOCKERFILE_FOLDER=
VAR_PROJECT_NAME=
VAR_DEVOPS_DIR=

# Declare other vars
VAR_CONTAINER_TAG="latest"
VAR_CONTAINER_TARGET=
ARG_TARGET=build

# Following will be filled from script arguments
ARG_NOCACHE=
ARG_PULL=
ARG_CONFIG_FILE=aws-deploy.cfg

# TERMINAL COLORS
COL_RED='\033[1;31m'
COL_YELLOW='\033[1;33m'
COL_GREEN='\033[0;32m'
COL_BLUE='\033[0;34m'
COL_NC='\033[0m' # No Color

function config_read_file() {
    (grep -E "^${2}=" -m 1 "${1}" 2>/dev/null || echo "VAR=__UNDEFINED__") | head -n 1 | cut -d '=' -f 2-;
}

function config_get() {
    val="$(config_read_file ${ARG_CONFIG_FILE} "${1}")";
    printf -- "%s" "${val}";
}

# Main flow
function fnc_main()
{
    fnc_parse_args "$@"
    fnc_load_config

    fnc_update_git
    fnc_choose_image
    fnc_choose_tag
    fnc_docker
    fnc_clean

    return
}

function fnc_parse_args()
{
    while [ $# -gt 0 ]
    do
        case "${1}" in
            -c|--config)
                shift
                ARG_CONFIG_FILE="${1}"
                shift
            ;;
            --no-cache)
                shift
                ARG_NOCACHE="--no-cache"
            ;;
            --pull)
                shift
                ARG_PULL="--pull"
            ;;
            *)
                echo -e "\n${COL_RED}ERROR: UNKNOWN ARGUMENT ${1}${COL_NC}\n"
                exit 1
            ;;
        esac
    done

    return
}

function fnc_load_config()
{
    declare -g -A VAR_VALID_TARGETS=$(config_get aws_account_targets)
    VAR_VALID_IMAGES_LIST=($(config_get build_images_list))
    VAR_DOCKERFILE_FOLDER=$(config_get build_images_dockerfile_folder)
    VAR_PROJECT_NAME=$(config_get project)
    VAR_DEVOPS_DIR=$(config_get dir_devops)
}

function fnc_update_git()
{
    echo -e "${COL_RED}"
    read -r -p "Ensure the devops repo is on the correct branch.  Continue? [y/n]" response
    echo -e "${COL_NC}"

    case $response in
        [yY][eE][sS]|[yY])
            echo -e "\n${COL_GREEN}Pulling latest changes from Git (Devops repo)${COL_NC}\n"

            (cd ${VAR_DEVOPS_DIR} && git pull)
            ;;
        *)
            echo -e "${COL_RED}Image was not updated${COL_NC}"
            exit
            ;;
    esac

    return
}

function fnc_choose_image()
{
    echo -e "\n${COL_YELLOW}Choose image${COL_NC}\n"

    PS3=$'\n'"Which image would you like to update? "

    select OPT in "${VAR_VALID_IMAGES_LIST[@]}"

    do
        if [[ -z $OPT ]]; then
           echo -e "${COL_RED}Invalid option${COL_NC}"
        else
            VAR_CONTAINER_TARGET="${OPT}"
            break
        fi
    done

    return
}

function fnc_choose_tag()
{
    echo -e "${COL_YELLOW}"
    read -r -p "Choose tag: [latest] " response
    echo -e "${COL_NC}"

    if [[ ! -z "${response}" ]]; then
        VAR_CONTAINER_TAG=$response
    fi

    return
}

function fnc_docker()
{
    VAR_BUILDBASE=false
    VAR_REDEPLOY=false

    VAR_CONTAINER_DIR="${VAR_DEVOPS_DIR}/docker/containers/${VAR_DOCKERFILE_FOLDER}"

    source "${VAR_SCRIPT_DIR}/release-docker.sh"

    return
}

function fnc_clean()
{
    echo -e "\n${COL_GREEN}Cleanup: Remove dangling docker images${COL_NC}\n"

    docker images -f dangling=true -q | xargs --no-run-if-empty docker rmi -f

    return
}


# RUN
fnc_main "$@"
