FROM node:20-alpine as frontend

RUN mkdir -p /app
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY trader-app/package*.json ./
# Install dependencies
RUN --mount=type=cache,target=/root/.npm npm install

COPY trader-app/src src
COPY trader-app/public public

CMD npm run build && rm -rf /build/* && cp -r /app/build/. /build/