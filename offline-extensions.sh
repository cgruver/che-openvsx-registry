#!/usr/bin/env bash

function downloadExtension() {

  local url=${1}
  local fileName=${2}
  local namespace=${3}

  echo "Downloading: ${url}"
  curl -sL "${url}" -o "${WORK_DIR}/${fileName}"
  echo "${namespace}" >> ${WORK_DIR}/tmp-namespace.list
  echo "${fileName}" >> ${WORK_DIR}/bundle.list

}

function fetchExtensionData() {

  local ext_data="${1}"

  has_linux_x64=$(echo "${ext_data}" | yq ".downloads | has(\"linux-x64\")")
  has_universal=$(echo "${ext_data}" | yq ".downloads | has(\"universal\")")
  if [[ ${has_linux_x64} == "true" ]]
  then
    url=$(echo "${ext_data}" | yq e ".downloads.linux-x64")
  elif [[ ${has_universal} == "true" ]]
  then
    url=$(echo "${ext_data}" | yq e ".downloads.universal")
  else
    url=$(echo "${ext_data}" | yq e ".files.download")
  fi

  local version=${2}
  local name=${3}

  name=$(echo "${ext_data}" | yq e ".name")
  namespace=$(echo "${ext_data}" | yq e ".namespace")
  version=$(echo "${ext_data}" | yq e ".version")
  downloadExtension ${url} ${namespace}-${name}-${version}.vsix ${namespace}
  
}

function getUrl() {

  local ext_data="${1}"

  echo "***************************************"
  echo "${ext_data}"
  echo "***************************************"
  has_linux_x64=$(echo "${ext_data}" | yq ".downloads | has(\"linux-x64\")")
  has_universal=$(echo "${ext_data}" | yq ".downloads | has(\"universal\")")
  if [[ ${has_linux_x64} == "true" ]]
  then
    url=$(echo "${ext_data}" | yq e ".downloads.linux-x64")
  elif [[ ${has_universal} == "true" ]]
  then
    url=$(echo "${ext_data}" | yq e ".downloads.universal")
  else
    url=$(echo "${ext_data}" | yq e ".files.download")
  fi
}

function fetchDependencyData() {

  local ext_data="${1}"
  local index=0

  num_deps=$(echo "${ext_data}" | yq e ".dependencies" | yq e 'length')
  while [[ ${index} -lt ${num_deps} ]]
  do
    dep_url=$(echo "${ext_data}" | yq e ".dependencies.[${index}].url")
    dep_metadata=$(curl -sLS "${dep_url}/latest" | yq -P ".")
    fetchExtensionData "${dep_metadata}"
    index=$(( ${index} + 1 ))
  done
}

function download() {

  local index=0

  WORK_DIR=$(mktemp -d)
  BUNDLE_NAME="openvsx-bundle-$(date +%m%d%Y%k%M%S).tar"

  num_ext=$(yq e ".extensions" ${EXTENSION_FILE} | yq e 'length')
  while [[ ${index} -lt ${num_ext} ]]
  do
    ext_id=$(yq e ".extensions.[${index}].id" ${EXTENSION_FILE})
    has_version=$(yq ".extensions.[${index}] | has(\"version\")" ${EXTENSION_FILE})
    has_url=$(yq ".extensions.[${index}] | has(\"url\")" ${EXTENSION_FILE})
    if [[ ${has_version} == "true" ]]
    then
      ext_version=$(yq e ".extensions.[${index}].version" ${EXTENSION_FILE})
    else
      ext_version="latest"
    fi
    if [[ ${has_url} == "true" ]]
    then
      ext_url=$(yq e ".extensions.[${index}].url" ${EXTENSION_FILE})
      downloadExtension ${ext_url} ${ext_id//./-}-${ext_version}.vsix $(echo ${ext_id} | cut -d"." -f1)
    else
      ext_path=${ext_id//./\/}
      ext_metadata=$(curl -sLS "https://open-vsx.org/api/${ext_path}/${ext_version}" | yq -P ".")
      fetchDependencyData "${ext_metadata}"
      fetchExtensionData "${ext_metadata}"
    fi
    index=$(( ${index} + 1 ))
  done
  cat ${WORK_DIR}/tmp-namespace.list | sort -u > ${WORK_DIR}/namespace.list
  rm ${WORK_DIR}/tmp-namespace.list
  tar -cvf ${BUNDLE_NAME} -C ${WORK_DIR} .
  rm -rf ${WORK_DIR}
  echo "Extension Bundle Created at: ./${BUNDLE_NAME}"
}

function upload() {

  WORK_DIR=$(mktemp -d)
  tar -xvf ${BUNDLE_NAME} -C ${WORK_DIR}
  for namespace in $(cat ${WORK_DIR}/namespace.list)
  do
    ovsx create-namespace ${namespace}
  done 
  for bundle in $(cat ${WORK_DIR}/bundle.list)
  do
    ovsx publish --skip-duplicate ${WORK_DIR}/${bundle}
  done
  rm -rf ${WORK_DIR}

}

function printHelp() {
  echo "wip"
}

for i in "$@"
do
  case $i in
    -d|--download)
      DOWNLOAD=true
    ;;
    -u|--upload)
      UPLOAD=true
    ;;
    -r=*|--registry=*)
      OVSX_REGISTRY_URL="${i#*=}"
    ;;
    -t=*|--token=*)
      OVSX_PAT="${i#*=}"
    ;;
    -f=*|--file=*)
      EXTENSION_FILE="${i#*=}"
    ;;
    -b=*|--bundle=*)
      BUNDLE_NAME="${i#*=}"
    ;;
    --help)
      printHelp
    ;;
  esac
done

if [[ ${DOWNLOAD} == "true" ]]
then
  download
fi

if [[ ${UPLOAD} == "true" ]]
then
  upload
fi