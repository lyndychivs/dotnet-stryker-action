#!/bin/sh

export PATH="$PATH:/root/.dotnet/tools"

if [ -n "$(echo $2 | grep -v '^[[:space:]]*$')" ]; then
  echo "dashboard-api-key provided"
  dotnet stryker --config-file $1 --dashboard-api-key $2 --version $3
else
  echo "dashboard-api-key not provided"
  dotnet stryker --config-file $1 --version $3
fi
