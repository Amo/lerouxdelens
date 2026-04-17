FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
COPY 2026.png /usr/share/nginx/html/2026.png
COPY banner.jpg /usr/share/nginx/html/banner.jpg
RUN rm -f /usr/share/nginx/html/50x.html

EXPOSE 80
