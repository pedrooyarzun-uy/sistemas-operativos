FROM node:current

COPY ./ /home/node/app

WORKDIR /home/node/app

RUN npm install

EXPOSE 5000

CMD ["npm", "start"]