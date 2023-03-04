#!/bin/bash

echo "Starting to publish extensions...."

containsElement () { for e in "${@:2}"; do [[ "$e" = "$1" ]] && return 0; done; return 1; }


# pull vsix from OpenVSX
WORK_DIR=$(mktemp -d)
openVsxSyncFileContent=$(cat ${SYNCH_FILE})
numberOfExtensions=$(echo "${openVsxSyncFileContent}" | jq ". | length")
listOfPublishers=()
IFS=$'\n' 

for i in $(seq 0 "$((numberOfExtensions - 1))"); do
    vsixFullName=$(echo "${openVsxSyncFileContent}" | jq -r ".[$i].id")
    vsixVersion=$(echo "${openVsxSyncFileContent}" | jq -r ".[$i].version")
    vsixDownloadLink=$(echo "${openVsxSyncFileContent}" | jq -r ".[$i].download")

    # extract from the vsix name the publisher name which is the first part of the vsix name before dot
    vsixPublisher=$(echo "${vsixFullName}" | cut -d '.' -f 1)

    # replace the dot by / in the vsix name
    vsixName=$(echo "${vsixFullName}" | sed 's/\./\//g')

    # if download wasn't set, try to fetch from openvsx.org
    if [[ $vsixDownloadLink == null ]]; then
        # grab metadata for the vsix file
        # if version wasn't set, use latest
        if [[ $vsixVersion == null ]]; then
            vsixMetadata=$(curl -sLS "https://open-vsx.org/api/${vsixName}/latest")
            
            # if version wasn't set in json, grab it from metadata and add it into the file
            vsixVersion=$(echo "${vsixMetadata}" | jq -r '.version')
        else
            vsixMetadata=$(curl -sLS "https://open-vsx.org/api/${vsixName}/${vsixVersion}")
        fi 
        # check there is no error field in the metadata
        if [[ $(echo "${vsixMetadata}" | jq -r ".error") != null ]]; then
            echo "Error while getting metadata for ${vsixFullName}"
            echo "${vsixMetadata}"
            exit 1
        fi
        
        # extract the download link from the json metadata
        vsixDownloadLink=$(echo "${vsixMetadata}" | jq -r '.files.download')
        # get linux-x64 download link
        vsixLinux64DownloadLink=$(echo "${vsixMetadata}" | jq -r '.downloads."linux-x64"')
        if [[ $vsixLinux64DownloadLink != null ]]; then
            vsixDownloadLink=$vsixLinux64DownloadLink
        fi
    fi

    echo "Downloading ${vsixDownloadLink} into ${vsixPublisher} folder..."

    vsixFilename="${WORK_DIR}/${vsixFullName}-${vsixVersion}.vsix"

    # download the vsix file in the publisher directory
    curl -sL "${vsixDownloadLink}" -o "${vsixFilename}"

    # check if publisher is in the list of publishers
    if ! containsElement "${vsixPublisher}" "${listOfPublishers[@]}"; then
        listOfPublishers+=("${vsixPublisher}")
        # create namespace
        ovsx create-namespace "${vsixPublisher}"
    fi

    # publish the file
    ovsx publish "${vsixFilename}"

    # remove the downloaded file
    rm "${vsixFilename}"

done;

rm -rf ${WORK_DIR}
