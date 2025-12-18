#!/bin/sh

export PATH="$PATH:/root/.dotnet/tools"

configFile=$1
dashboardApiKey=$2
version=$3

dashboardCommand=""
if [ -n "${dashboardApiKey}" ] && [ "${dashboardApiKey}" != "" ]; then
   echo "dashboard-api-key provided"
   dashboardCommand="--reporter Dashboard --dashboard-api-key $dashboardApiKey"
else
   echo "dashboard-api-key not provided"
fi

versionCommand=""
if [ -n "${version}" ] && [ "${version}" != "" ]; then
   echo "version provided: $version"
   versionCommand="--version $version"
else
   echo "version not provided"
fi

dotnet stryker --config-file $configFile $dashboardCommand $versionCommand