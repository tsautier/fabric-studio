FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY apex.png /usr/share/nginx/html/apex.png
COPY RWE_Enformer_Solar-auf-Bergen_1340x590.webp /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
