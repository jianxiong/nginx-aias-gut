FROM node:17-alpine
WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 443
CMD [ "node", "index.js" ]
