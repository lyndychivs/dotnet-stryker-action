#!/bin/sh

export PATH="$PATH:/root/.dotnet/tools"

if [[ -n "${2// /}" ]]; then
  echo "dashboard-api-key provided"
  dotnet stryker --config-file $1 --dashboard-api-key $2
else
  echo "dashboard-api-key not provided"
  dotnet stryker --config-file $1
fi
