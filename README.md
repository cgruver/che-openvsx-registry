# che-openvsx-registry

Self Hosted instance of Open VSX for disconnected OpenShift installations using Eclipse Che (OpenShift Dev Spaces)

```bash
podman build -t ${LOCAL_REGISTRY}/eclipse-che/open-vsx-server:latest .
podman push ${LOCAL_REGISTRY}/eclipse-che/open-vsx-server:latest
oc import-image open-vsx-server:latest --from=${PROXY_REGISTRY}/eclipse-che/open-vsx-server:latest --confirm -n che-openvsx
```

```bash
oc apply -f deploy.yaml
```

```bash
npm install -g ovsx
```

```bash
psql -d openvsx -c "INSERT INTO user_data (id, login_name) VALUES (1001, 'eclipse-che');"
psql -d openvsx -c "INSERT INTO personal_access_token (id, user_data, value, active, created_timestamp, accessed_timestamp, description) VALUES (1001, 1001, 'eclipse_che_token', true, current_timestamp, current_timestamp, 'extensions');"
psql -d openvsx -c "UPDATE user_data SET role='admin' WHERE user_data.login_name='eclipse-che';"
```

```bash
export OVSX_REGISTRY_URL=https://$(oc get route open-vsx-server -n che-openvsx -o jsonpath={.spec.host})
export OVSX_PAT=eclipse_che_token
export SYNCH_FILE=./openvsx-sync.json
export NODE_TLS_REJECT_UNAUTHORIZED='0'
```

```bash
psql -d openvsx -c "UPDATE personal_access_token SET active = false;"
```
