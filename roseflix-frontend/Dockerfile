# 1: base with dependencies
FROM node:15-alpine3.13 as builder
# Set the working directory inside the container
WORKDIR /app
# copy package dependencies files
COPY package*.json ./
# install dependencies
RUN npm install
# copy rest of the app
COPY . .
# setting env vars here since after "build" the env vars are being sealed into the files
# key for TMDB
ENV REACT_APP_API_KEY="some moviedb api key"
# address of the backend server
ENV REACT_APP_SERVER_URL=http://roseflix-backend-service:8080
# build production ready folder (named "build")
RUN npm run build


# 2: prod
FROM node:15-alpine3.13
# set nodejs env mode to production (won't install dev dependencies)
ENV NODE_ENV=production
# Set the working directory inside the container
WORKDIR /app
# copy package dependencies files
COPY package*.json ./
# install dependencies
RUN npm install
# copy the prod ready files from "build" folder on the previous step builder image
COPY --from=builder /app/build .
# install "serve", a little web server for our production-ready files, since "npm run" supports only dev mode.
RUN npm install --global serve
# tell serve to serve the current directory (workdir) files on port 80
EXPOSE 80
CMD  serve --listen 80
