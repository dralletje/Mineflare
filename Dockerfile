FROM dockerfile/nodejs

RUN npm install -g coffee-script
WORKDIR /app
ADD package.json /app/
RUN npm install
ADD . /app

EXPOSE 80
CMD coffee source/app.coffee
