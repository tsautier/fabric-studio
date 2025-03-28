FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY globex.png /usr/share/nginx/html/globex.png
COPY photo-1700716465891-9e5e9f501d7d.avif /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
