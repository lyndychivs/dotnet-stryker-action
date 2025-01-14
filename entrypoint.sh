#!/bin/sh

export PATH="$PATH:/root/.dotnet/tools"

dotnet stryker --config-file $1