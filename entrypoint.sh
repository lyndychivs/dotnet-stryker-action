#!/bin/sh

export PATH="$PATH:/root/.dotnet/tools"

configFile=$1
dashboardApiKey=$2
version=$3

if [ -n "$(echo $dashboardApiKey | grep -v '^[[:space:]]*$')" ]; then
  echo "dashboard-api-key provided"
  if [ -n "$(echo $version | grep -v '^[[:space:]]*$')" ]; then
    echo "version provided: $version"
    dotnet stryker --config-file $configFile --dashboard-api-key $dashboardApiKey --version $version
  else
    echo "version not provided"
    dotnet stryker --config-file $configFile --dashboard-api-key $dashboardApiKey
  fi
else
  echo "dashboard-api-key not provided"
  dotnet stryker --config-file $configFile
fi
