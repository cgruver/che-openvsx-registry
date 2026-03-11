Get Extension data

```bash
curl -sLS "https://open-vsx.org/api/redhat/java"

curl -sLS "https://open-vsx.org/api/v2/-/query"

curl -X GET 'https://open-vsx.org/api/v2/-/query?extensionId=redhat.java&includeAllVersions=true&targetPlatform=linux-x64&size=20&offset=0' -H 'accept: application/json'

  oc get clusterrolebindings -o json | jq '.items[] | select(.roleRef.name=="cluster-admin") | select(.subjects[].name=="admin" and .subjects[].kind=="User") | .subjects | length'
```

curl -X GET 'https://open-vsx.org/api/v2/-/query?extensionId=redhat.java&includeAllVersions=true&targetPlatform=linux-x64&size=20&offset=0' -H 'accept: application/json' | jq '.extensions[] | select(.preRelease==false)'

jq -s '[.[] | select(.some_field == "some_value")][0]'
jq -n 'last(inputs)'


curl -X GET 'https://open-vsx.org/api/v2/-/query?extensionId=redhat.java&includeAllVersions=true&targetPlatform=linux-x64&size=100&offset=0' -H 'accept: application/json' | jq '.extensions[] | select(.preRelease==false)'

