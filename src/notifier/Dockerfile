FROM mcr.microsoft.com/dotnet/sdk:8.0

WORKDIR /app
COPY *.cs .
COPY appsettings.json .
COPY *.csproj .
RUN dotnet publish -c Release -o out

ENTRYPOINT [ "./out/Notifier", "--urls", "http://*:5000" ]