FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY acme.png /usr/share/nginx/html/acme.png
COPY Hero_image_1_3cde22c463.jpg /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
