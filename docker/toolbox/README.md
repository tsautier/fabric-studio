# Stoppe und entferne eventuell laufende Container mit image 'toolbox'
docker ps -a --filter ancestor=toolbox --format "{{.ID}}" | xargs -r docker stop
docker ps -a --filter ancestor=toolbox --format "{{.ID}}" | xargs -r docker rm

export BUILD_VERSION=1.2.2
docker build -f Dockerfile -t toolbox:$BUILD_VERSION .
docker tag toolbox:$BUILD_VERSION sadubois/toolbox:$BUILD_VERSION
docker push sadubois/toolbox:$BUILD_VERSION

# Neu starten
docker run -d -p 8080:8080 toolbox

