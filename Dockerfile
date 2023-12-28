FROM node:latest

COPY . /data

WORKDIR /data

RUN npm install

CMD npm run server

EXPOSE 4200


