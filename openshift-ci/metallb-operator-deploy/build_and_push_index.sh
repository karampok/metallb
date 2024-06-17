#!/bin/bash

yum install jq git wget -y
cd /tmp/metallb-operator-deploy

wget -q https://github.com/operator-framework/operator-registry/releases/download/v1.23.0/linux-amd64-opm
mv linux-amd64-opm opm
chmod +x ./opm

set +x
pass=$( jq .\"image-registry.openshift-image-registry.svc:5000\".auth /var/run/secrets/openshift.io/push/.dockercfg )
pass=`echo ${pass:1:-1} | base64 -d`
podman login -u serviceaccount -p ${pass:8} image-registry.openshift-image-registry.svc:5000 --tls-verify=false
set -x

podman build -f bundleci.Dockerfile --tag image-registry.openshift-image-registry.svc:5000/openshift-marketplace/metallboperatorbundle:latest .
podman push image-registry.openshift-image-registry.svc:5000/openshift-marketplace/metallboperatorbundle:latest --tls-verify=false

./opm index --skip-tls add --bundles image-registry.openshift-image-registry.svc:5000/openshift-marketplace/metallboperatorbundle:latest --tag image-registry.openshift-image-registry.svc:5000/openshift-marketplace/metallbindex:latest -p podman --mode semver
podman push image-registry.openshift-image-registry.svc:5000/openshift-marketplace/metallbindex:latest --tls-verify=false
