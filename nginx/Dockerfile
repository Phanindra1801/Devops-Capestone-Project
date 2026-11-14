
# Stage 1: Build React frontend
FROM node:22-alpine AS frontend-build

WORKDIR /app

COPY frontend/package*.json ./

RUN npm ci

COPY frontend/ ./

RUN npm run build


# Stage 2: Create Nginx production image
FROM nginx:1.27-alpine

# Remove default Nginx website configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy React production files
COPY --from=frontend-build /app/dist/ /usr/share/nginx/html/

# Copy custom Nginx configuration
COPY nginx/active/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
