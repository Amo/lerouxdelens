FROM nginx:1.27-alpine

COPY index.html /usr/share/nginx/html/index.html
COPY me.jpg /usr/share/nginx/html/me.jpg

EXPOSE 80
