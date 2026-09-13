FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies including native sqlite3 bindings
RUN apk add --no-cache python3 make g++ \
    && npm install --production \
    && apk del python3 make g++

# Copy server code and public assets
COPY . .

# Expose port
EXPOSE 3000

ENV PORT=3000

CMD ["npm", "start"]
