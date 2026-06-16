FROM node:21 AS backend-builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
# If you add real tests, enable this step
# RUN npm test

FROM node:21-slim

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY --from=backend-builder /app .
ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080
CMD ["npm", "start"]
