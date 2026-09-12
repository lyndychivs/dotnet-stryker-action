FROM mcr.microsoft.com/dotnet/sdk:10.0

LABEL org.opencontainers.image.source="https://github.com/lyndychivs/dotnet-stryker-action"
LABEL org.opencontainers.image.description="GitHub Action for mutation testing with Stryker.NET via Docker"
LABEL org.opencontainers.image.licenses="MIT"

COPY --chmod=755 entrypoint.sh /entrypoint.sh

RUN dotnet tool install -g dotnet-stryker --version 5.0.0

ENTRYPOINT ["/entrypoint.sh"]
