FROM busybox:latest

COPY index.html /www/html/index.html
COPY FortidemoCA.crt /

# Füge Eintrag zu /etc/hosts hinzu
#RUN echo "10.1.1.1 proxy.fabric-studio.fortidemo.ch" >> /etc/hosts

EXPOSE 80
CMD ["sh", "-c", "while true; do sleep 3600; done"]
