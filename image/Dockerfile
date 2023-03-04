FROM registry.access.redhat.com/ubi9/ubi-minimal

COPY --from=ghcr.io/eclipse/openvsx-server:v0.9.0 --chown=0:0 /home/openvsx/server /openvsx-server
COPY ./application.yaml /openvsx-server/config/
COPY ./entrypoint.sh /

ENV JVM_ARGS="-DSPDXParser.OnlyUseLocalLicenses=true -Xmx2048m"

RUN microdnf install --nodocs -y java-11-openjdk && microdnf clean all
ENTRYPOINT ["/entrypoint.sh"]