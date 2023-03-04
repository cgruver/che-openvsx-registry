#!/usr/bin/env bash

function download() {

}

function upload() {

}

function printHelp() {

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
    --help)
      printHelp
    ;;
  esac
done

