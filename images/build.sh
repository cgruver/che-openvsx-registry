#!/usr/bin/env bash

NODE_VERSION=${NODE_VERSION:=v18.15.0}
TOOLS_IMAGE_PATH=${TOOLS_IMAGE_PATH:=quay.io/cgruver0/che/dev-tools}
TOOLS_IMAGE_TAG=${TOOLS_IMAGE_TAG:=latest}
DEMO_IMAGE_PATH=${DEMO_IMAGE_PATH:=quay.io/cgruver0/che/che-demo-app}
DEMO_IMAGE_TAG=${DEMO_IMAGE_TAG:=latest}
TOOLS_DIR=${TOOLS_DIR:=./tools}

function getTools() {
  rm -rf ${TOOLS_DIR}
  mkdir -p ${TOOLS_DIR}/bin

  ## NodeJS
  TEMP_DIR="$(mktemp -d)"
  curl -fsSL -o ${TEMP_DIR}/node.tz https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz
  tar -x --no-auto-compress -f ${TEMP_DIR}/node.tz -C ${TEMP_DIR}
  mv ${TEMP_DIR}/node-${NODE_VERSION}-linux-x64 ${TOOLS_DIR}/node
  rm -rf "${TEMP_DIR}"

  ## Create Symbolic Links to executables
  cd ${TOOLS_DIR}/bin
  ln -s ../quarkus-cli/bin/quarkus quarkus
  ln -s ../maven/bin/mvn mvn
  ln -s ../node/bin/node node
  ln -s ../node/bin/npm npm
  ln -s ../node/bin/corepack corepack
  ln -s ../node/bin/npx npx
  ln -s /projects/bin/oc oc
  ln -s /projects/bin/kubectl kubectl
  cd -
}

function buildToolsImage() {
  podman build -t ${TOOLS_IMAGE_PATH}:${TOOLS_IMAGE_TAG} -f dev-tools.Containerfile .
  podman push ${TOOLS_IMAGE_PATH}:${TOOLS_IMAGE_TAG}
}

function buildDevImage() {
  podman build -t ${DEMO_IMAGE_PATH}:${DEMO_IMAGE_TAG} --build-arg TOOLS_IMAGE_TAG=${TOOLS_IMAGE_TAG} -f che-demo-app.Containerfile .
  podman push ${DEMO_IMAGE_PATH}:${DEMO_IMAGE_TAG}
}

for i in "$@"
do
  case $i in
    -g)
      getTools
    ;;
    -t)
      buildToolsImage
    ;;
    -d)
      buildDevImage
    ;;
    *)
       # catch all
    ;;
  esac
done
