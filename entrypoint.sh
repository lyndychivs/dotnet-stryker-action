#!/bin/sh
set -e

export PATH="$PATH:/root/.dotnet/tools"

set -- --config-file "${INPUT_CONFIGURATIONFILE}"
echo "config-file: ${INPUT_CONFIGURATIONFILE}"

if [ -n "${INPUT_DASHBOARDAPIKEY}" ]; then
   echo "dashboard-api-key: provided"
   echo "version: ${GITHUB_REF_NAME}"
   set -- "$@" --reporter Dashboard --dashboard-api-key "${INPUT_DASHBOARDAPIKEY}" --version "${GITHUB_REF_NAME}"
else
   echo "dashboard-api-key: not provided"
fi

dotnet stryker "$@"
