FROM alpine:latest

COPY index.html /www/index.html
COPY FortidemoCA.crt /

# Add Curl
RUN apk add --no-cache curl busybox-extras

EXPOSE 80
CMD ["sh", "-c", "httpd -f -p 8080 -h /www"]
