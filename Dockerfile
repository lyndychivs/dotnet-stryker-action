FROM mcr.microsoft.com/dotnet/sdk:8.0

COPY --chmod=755 entrypoint.sh /entrypoint.sh

RUN dotnet tool install -g dotnet-stryker --version 4.6.0

ENTRYPOINT ["/entrypoint.sh"]
