FROM node:22-slim
WORKDIR /app
COPY package.json .
RUN npm install --production
COPY server.js .
COPY badge.js* ./
VOLUME /app/data
ENV DB_PATH=/app/data/helios.db
EXPOSE 3000
CMD ["node", "server.js"]
