FROM node:24.21.0-trixie-slim

WORKDIR /app

COPY ./package*.json /

RUN npm install

EXPOSE 5173

COPY . .

CMD [ "npm","run","dev", "--","--host","0.0.0.0","--port","5173" ]


