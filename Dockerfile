FROM mcr.microsoft.com/dotnet/sdk:8.0

RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 9.0 --install-dir /usr/share/dotnet

RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 10.0 --install-dir /usr/share/dotnet

COPY --chmod=755 entrypoint.sh /entrypoint.sh

RUN dotnet tool install -g dotnet-stryker

ENTRYPOINT ["/entrypoint.sh"]
