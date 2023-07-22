FROM nginx:latest

EXPOSE 8118 8119

WORKDIR /etc/nginx

COPY nginx.conf .