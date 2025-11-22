FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["Authentication/", "Authentication/"]
COPY ["Common/", "Common/"]
RUN dotnet restore "Authentication/Authentication.csproj"
RUN dotnet publish "Authentication/Authentication.csproj" -c Release -o /app /p:UseAppHost=false --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Authentication.dll"]
EXPOSE 80