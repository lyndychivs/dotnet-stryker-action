FROM mcr.microsoft.com/dotnet/sdk:9.0 AS dotnet9
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS dotnet10

FROM mcr.microsoft.com/dotnet/sdk:8.0

LABEL org.opencontainers.image.source="https://github.com/lyndychivs/dotnet-stryker-action"
LABEL org.opencontainers.image.description="GitHub Action for mutation testing with Stryker.NET via Docker"
LABEL org.opencontainers.image.licenses="MIT"

COPY --from=dotnet9 /usr/share/dotnet /usr/share/dotnet
COPY --from=dotnet10 /usr/share/dotnet /usr/share/dotnet

COPY --chmod=755 entrypoint.sh /entrypoint.sh

RUN dotnet tool install -g dotnet-stryker --version 4.14.1

ENTRYPOINT ["/entrypoint.sh"]
