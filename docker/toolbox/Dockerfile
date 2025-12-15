FROM alpine:latest

# Install Python 3
RUN apk add --no-cache python3 curl ca-certificates jq

# Copy the slow HTTP server script
COPY slowserver.py /slowserver.py 

# Expose port 8080
EXPOSE 8080

# Run the Python server
CMD ["python3", "/slowserver.py"]
