FROM nginx:stable-alpine
COPY index.html /usr/share/nginx/html/index.html
COPY screen/ /usr/share/nginx/html/screen/
