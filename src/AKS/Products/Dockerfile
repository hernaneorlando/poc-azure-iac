FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["Products/", "Products/"]
COPY ["Common/", "Common/"]
RUN dotnet restore "Products/Products.csproj"
RUN dotnet publish "Products/Products.csproj" -c Release -o /app /p:UseAppHost=false --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Products.dll"]
EXPOSE 80