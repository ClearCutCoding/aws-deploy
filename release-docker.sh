#!/usr/bin/env bash
set -e

# Used args passed in from parent script
# ARG_APP
# ARG_TARGET
# ARG_NOCACHE
# VAR_DEVOPS_DIR
# VAR_VALID_TARGETS
# VAR_CONTAINER_TARGET
# VAR_CONTAINER_TAG
# VAR_BUILDBASE
# VAR_REDEPLOY
# VAR_CONTAINER_DIR
# VAR_PROJECT_NAME

# Declare arguments and global vars
declare -A VAR_ECS_CLUSTERS=$(config_get aws_ecs_clusters)
declare -A VAR_ECS_SERVICES=$(config_get aws_ecs_services)

VAR_ECR_REGION=$(config_get aws_ecr_region)

VAR_CONTAINER_IMAGENAME_LOCAL="${VAR_PROJECT_NAME}-${ARG_TARGET}-${VAR_CONTAINER_TARGET}"
VAR_CONTAINER_IMAGENAME_LOCAL_BASE="${VAR_PROJECT_NAME}-${ARG_TARGET}-${VAR_CONTAINER_TARGET}-base"
VAR_CONTAINER_IMAGENAME_REMOTE="${ARG_TARGET}-${VAR_CONTAINER_TARGET}"
VAR_CONTAINER_IMAGENAME_REMOTE_PREFIX="${VAR_VALID_TARGETS[$ARG_TARGET]}.dkr.ecr.${VAR_ECR_REGION}.amazonaws.com"

# Main flow
function fnc_main() {
    echo -e "\n${COL_GREEN}START DOCKER PROCESS - ${VAR_CONTAINER_IMAGENAME_LOCAL}${COL_NC}\n"

    fnc_buildbase
    fnc_build
    fnc_tag
    fnc_logon
    fnc_push
    fnc_redeploy
    fnc_delete_untagged

    echo -e "\n${COL_GREEN}FINISH DOCKER PROCESS - ${VAR_CONTAINER_IMAGENAME_LOCAL}${COL_NC}\n"

    return
}

function fnc_buildbase()
{
    if [ ${VAR_BUILDBASE} = false ]; then
        echo -e "\n${COL_RED}Skipping base image build${COL_NC}\n"
        return
    fi

    LOCALVAR_IMAGE_INSTALLATIONS=${VAR_CONTAINER_IMAGENAME_LOCAL_BASE}-installation:${VAR_CONTAINER_TAG}
    LOCALVAR_IMAGE_CONFIGURATIONS=${VAR_CONTAINER_IMAGENAME_LOCAL_BASE}-configuration:${VAR_CONTAINER_TAG}

    echo -e "\n${COL_GREEN}Build Base Image - ${LOCALVAR_IMAGE_INSTALLATIONS}${COL_NC}\n"

    (cd ${VAR_CONTAINER_DIR} && docker build ${ARG_NOCACHE} --build-arg target=${ARG_TARGET} -f ${VAR_CONTAINER_TARGET}_dockerfile-base-installation -t ${LOCALVAR_IMAGE_INSTALLATIONS} .)

    echo -e "\n${COL_GREEN}Build Base Image - ${LOCALVAR_IMAGE_CONFIGURATIONS}${COL_NC}\n"

    (cd ${VAR_CONTAINER_DIR} && docker build ${ARG_NOCACHE} --build-arg target=${ARG_TARGET} --build-arg targetFrom=${ARG_TARGET} -f ${VAR_CONTAINER_TARGET}_dockerfile-base-configuration -t ${LOCALVAR_IMAGE_CONFIGURATIONS} .)

    return
}

function fnc_build()
{
    LOCALVAR_IMAGE=${VAR_CONTAINER_IMAGENAME_LOCAL}:${VAR_CONTAINER_TAG}

    echo -e "\n${COL_GREEN}Build Image - ${LOCALVAR_IMAGE}${COL_NC}\n"

    if [ ${VAR_DEV_BASETARGET} ]; then
      (cd ${VAR_CONTAINER_DIR} && docker build ${ARG_NOCACHE} --build-arg target=${ARG_TARGET} --build-arg basetarget=${VAR_DEV_BASETARGET} -f ${VAR_CONTAINER_TARGET}_dockerfile-build-${ARG_TARGET} -t ${LOCALVAR_IMAGE} .)
    else
      (cd ${VAR_CONTAINER_DIR} && docker build ${ARG_NOCACHE} --build-arg target=${ARG_TARGET} -f ${VAR_CONTAINER_TARGET}_dockerfile-build-${ARG_TARGET} -t ${LOCALVAR_IMAGE} .)
    fi

    return
}

function fnc_tag()
{
    echo -e "\n${COL_GREEN}Tag Image${COL_NC}\n"

    docker tag ${VAR_CONTAINER_IMAGENAME_LOCAL}:${VAR_CONTAINER_TAG} ${VAR_CONTAINER_IMAGENAME_REMOTE_PREFIX}/${VAR_CONTAINER_IMAGENAME_REMOTE}:${VAR_CONTAINER_TAG}

    return
}

function fnc_logon()
{
    local RCLOGIN

    echo -e "\n${COL_GREEN}Logon${COL_NC}\n"

    PASS=$(aws ecr get-login-password --region ${VAR_ECR_REGION} --profile ${VAR_PROJECT_NAME}-${ARG_TARGET})
    docker login -u AWS -p ${PASS} https://${VAR_CONTAINER_IMAGENAME_REMOTE_PREFIX}

    return
}

function fnc_push()
{
    echo -e "\n${COL_GREEN}Push To ECS${COL_NC}\n"

    docker push ${VAR_CONTAINER_IMAGENAME_REMOTE_PREFIX}/${VAR_CONTAINER_IMAGENAME_REMOTE}:${VAR_CONTAINER_TAG}

    return
}

function fnc_redeploy()
{
    if [ ${VAR_REDEPLOY} = false ]; then
        echo -e "\n${COL_RED}Skipping re-deployment${COL_NC}\n"
        return
    fi

    echo -e "\n${COL_GREEN}Re-deploy ECS Containers${COL_NC}\n"

    local CLUSTER=${VAR_ECS_CLUSTERS[${ARG_APP}-${ARG_TARGET}]}

    local SERVICE_KEY=${VAR_CONTAINER_TARGET}-${ARG_TARGET}
    local SERVICE=${VAR_ECS_SERVICES[${SERVICE_KEY}]}

    aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE} --force-new-deployment --profile ${VAR_PROJECT_NAME}-${ARG_TARGET} > /dev/null

    return
}

function fnc_delete_untagged()
{
    echo -e "\n${COL_GREEN}Delete old untagged images${COL_NC}\n"

    aws ecr list-images --profile ${VAR_PROJECT_NAME}-${ARG_TARGET} --repository-name ${VAR_CONTAINER_IMAGENAME_REMOTE} --query 'imageIds[?type(imageTag)!=`string`].[imageDigest]' --output text | while read line; do aws ecr batch-delete-image --profile ${VAR_PROJECT_NAME}-${ARG_TARGET} --repository-name ${VAR_CONTAINER_IMAGENAME_REMOTE} --image-ids imageDigest=$line; done

    return
}

# RUN
fnc_main "$@"
