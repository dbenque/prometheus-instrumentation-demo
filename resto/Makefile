BUILD_DIR=${GOPATH}/src/github.com/dbenque/prometheus-instrumentation-demo/resto
BINARY = resto
GOARCH = amd64
DOCKER_IMAGE= prom-demo-resto
VERSION=$(shell git tag|tail -1)
COMMIT=$(shell git rev-parse HEAD)
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
DATE=$(shell date +%Y-%m-%d)
GOOS =$(shell uname -s | tr '[:upper:]' '[:lower:]')

# Setup the -ldflags option for go build here, interpolate the variable values
LDFLAGS = -ldflags "-X main.VERSION=${VERSION} -X main.COMMIT=${COMMIT} -X main.BRANCH=${BRANCH} -X main.BUILDTIME=${DATE} -s"

build:
	cd ${BUILD_DIR}; \
	CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build -a -installsuffix cgo ${LDFLAGS} -o ${GOPATH}/bin/${BINARY}-${GOOS}-${GOARCH} . ; \
	cd - >/dev/null	

docker: build
	rm ${BUILD_DIR}/docker/${BINARY}
	cp ${GOPATH}/bin/${BINARY}-${GOOS}-${GOARCH} ${BUILD_DIR}/docker/${BINARY}
	cd ${BUILD_DIR}/docker; \
	docker build -t ${DOCKER_IMAGE} .
	cd - >/dev/null

clean:
	rm -f ${GOPATH}/bin/${BINARY}-*-${GOARCH}

.PHONY: build clean docker
