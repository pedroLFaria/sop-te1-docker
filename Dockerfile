FROM mcr.microsoft.com/windows/servercore:ltsc2022 as installer

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';$ProgressPreference='silentlyContinue';"]

RUN Invoke-WebRequest -OutFile nodejs.zip -UseBasicParsing "https://nodejs.org/dist/v16.13.0/node-v16.13.0-win-x64.zip"; `Expand-Archive nodejs.zip -DestinationPath C:\; `Rename-Item "C:\\node-v16.13.0-win-x64" c:\nodejs

FROM mcr.microsoft.com/windows/nanoserver:ltsc2022 as builder

WORKDIR C:\nodejs
COPY --from=installer C:\nodejs\ .
RUN SETX PATH C:\nodejs
RUN npm config set registry https://registry.npmjs.org/

WORKDIR /app
COPY package*.json ./
COPY tsconfig*.json ./
COPY ./src ./src
RUN npm ci --quiet && npm run build

FROM mcr.microsoft.com/windows/nanoserver:ltsc2022

WORKDIR C:\nodejs
COPY --from=installer C:\nodejs\ .
RUN SETX PATH C:\nodejs
RUN npm config set registry https://registry.npmjs.org/

WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --quiet --only=production
COPY --from=builder ./app/dist ./dist
EXPOSE 4000
CMD npm run start:prod


