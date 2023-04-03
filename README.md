# che-openvsx-registry

Self Hosted instance of Open VSX for disconnected OpenShift installations using Eclipse Che (OpenShift Dev Spaces)

## Prerequisites

NodeJS v14+

YQ YAML CLI - [https://mikefarah.gitbook.io/yq/](https://mikefarah.gitbook.io/yq/)

## Build the OpenVSX Image

```bash
cd image
export OPEN_VSX_VERSION=v0.9.7
export REGISTRY=<url-of-your-registry>
podman build --build-arg OPEN_VSX_VERSION=${OPEN_VSX_VERSION} -t ${REGISTRY}/che/open-vsx-server:${OPEN_VSX_VERSION} -f ./Containerfile .
```

### Push To Registry

```bash
podman push ${REGISTRY}/che/open-vsx-server:${OPEN_VSX_VERSION}
```

### Create Image Stream

```bash
cd ..
oc apply -f namespace.yaml
oc import-image open-vsx-server:${OPEN_VSX_VERSION} --from=${REGISTRY}/che/open-vsx-server:${OPEN_VSX_VERSION} --confirm -n che-openvsx
```

### Deploy Postgres

```bash
oc apply -f deploy-postgres.yaml
```

```bash
oc wait --for=condition=Available deployment/open-vsx-pg -n che-openvsx --timeout=180s
```

### Deploy Open VSX Registry

```bash
envsubst < ./deploy-openvsx.yaml | oc apply -f -
```

```bash
oc wait --for=condition=Available deployment/open-vsx-server -n che-openvsx --timeout=180s
```

```bash
OVSX_URL=https://$(oc get route open-vsx-server -n che-openvsx -o jsonpath={.spec.host})

oc patch CheCluster eclipse-che -n eclipse-che --type merge --patch "{\"spec\":{\"components\":{\"pluginRegistry\":{\"openVSXURL\":\"${OVSX_URL}\"}}}}"

oc patch CheCluster eclipse-che -n eclipse-che --type merge --patch '{"spec":{"components":{"pluginRegistry":{"openVSXURL":"http://open-vsx-server.che-openvsx.svc.cluster.local:8080"}}}}'
```

### Create Access Token

Execute the following commands in a terminal on the Postgres Pod

```bash
PG_POD=$(oc get pods --selector name=open-vsx-pg -n che-openvsx -o name)

oc rsh -n che-openvsx ${PG_POD} bash "-c" "PGDATA=/var/lib/pgsql/data psql -d openvsx -c \"INSERT INTO user_data (id, login_name) VALUES (1001, 'eclipse-che');\" && \
  psql -d openvsx -c \"INSERT INTO personal_access_token (id, user_data, value, active, created_timestamp, accessed_timestamp, description) VALUES (1001, 1001, 'eclipse_che_token', false, current_timestamp, current_timestamp, 'extensions');\" && \
  psql -d openvsx -c \"UPDATE user_data SET role='admin' WHERE user_data.login_name='eclipse-che';\""
```

### Install `ovsx` Command Line

```bash
npm install -g ovsx
```

## Download Extensions

```bash
./offline-extensions.sh -d -f=extension-list.yaml 
```

Note the name of the bundle that is created.

## Prepare For Extension Import

### Enable Access Token

```bash
PG_POD=$(oc get pods --selector name=open-vsx-pg -n che-openvsx -o name)
oc rsh -n che-openvsx ${PG_POD} bash "-c" "PGDATA=/var/lib/pgsql/data psql -d openvsx -c \"UPDATE personal_access_token SET active = true;\""
```

### Set `ovsx` Environment

```bash
export OVSX_REGISTRY_URL=https://$(oc get route open-vsx-server -n che-openvsx -o jsonpath={.spec.host})
export OVSX_PAT=eclipse_che_token
export NODE_TLS_REJECT_UNAUTHORIZED='0'
```

### Import Extensions

```bash
./offline-extensions.sh -u -b=/path/to/the/openvsx-bundle-****.tar
```

### Disable Access Token

Execute the following command in a terminal on the Postgres Pod

```bash
oc rsh -n che-openvsx ${PG_POD} bash "-c" "PGDATA=/var/lib/pgsql/data psql -d openvsx -c \"UPDATE personal_access_token SET active = false;\""
```
