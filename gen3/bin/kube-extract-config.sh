#!/bin/bash
#
# Little helper derives terraform and k8s configuration
# from kubernetes secrets if possible.
# Generates
#    $XDG_RUNTIME_DIR/kube-extract-config/creds.json, config.tfvars, and 00configmap.yaml
# Requries g3kubectl to be on the path and configured.
#

set -e

source "${GEN3_HOME}/gen3/lib/utils.sh"
gen3_load "gen3/gen3setup"

# harvest some variables
vpcName="$(g3kubectl get configmaps/global -o=jsonpath='{.data.environment}')$(date +%Y%m%d)"
hostname=""
dictionaryUrl=""
revproxyArn=""
indexdDbPassword=""
indexdDbSchema=""
fenceDbUser=""
fenceDbPassword=""
fenceDbSchema=""
amanuensisDbUser=""
amanuensisDbPassword=""
amanuensisDbSchema=""
dataReleaseBucket=""
dataReleaseAwsId=""
dataReleaseAwsSecret=""
googleClientId=""
googleClientSecret=""
gdcapiDbUser=""
gdcapiDbPassword=""
gdcapiDbSchema="gdcapi"
gdcapiIndexdSecret=""
peregrineDbPassword=""
sheepdogDbPassword=""

workFolder="${XDG_RUNTIME_DIR:-/tmp}/vpcInfo/${vpcName}"
mkdir -p -m 0700 "$workFolder"
cd "$workFolder"

for fileName in 00configmap.yaml creds.json config.tfvars; do
  if [[ -f $fileName ]]; then
    echo "ERROR: bailing out - $workFolder/$fileName already exists"
    exit 1
  fi
done

echo "Preparing output under $workFolder"

# install json query helper if necessary ...
if ! which jq > /dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  sudo -E apt install -y jq
fi

g3kubectl get configmaps/global -o yaml > 00configmap.yaml

# Note that legacy commons may not have the dictonary_url set ...
hostname=$(gen3 api hostname)
dictionaryUrl=$(g3kubectl get configmaps/global -o=jsonpath='{.data.dictionary_url}')
revproxyArn=$(g3kubectl get configmaps/global -o=jsonpath='{.data.revproxy_arn}')

# Legacy commons may not have jwt keys
if g3kubectl get secrets/jwt-keys > /dev/null 2>&1; then
  mkdir -p -m 0700 ./jwt-keys
  for keyName in jwt_public_key.pem jwt_private_key.pem jwt-keys.tar; do
    g3kubectl get secrets/fence-jwt-keys -o=json | jq -r ".data[\"$keyName\"]" | base64 --decode > "./jwt-keys/$keyName"
  done
fi

if g3kubectl get secrets/fence-ssh-keys > /dev/null 2>&1; then
  mkdir -p -m 0700 ./ssh-keys
  for keyName in id_rsa id_rsa.pub; do
    g3kubectl get secrets/fence-ssh-keys -o=json | jq -r ".data[\"$keyName\"]" | base64 --decode > "./ssh-keys/$keyName"
  done
fi

mkdir -p -m 0700 apis_configs
if g3kubectl get configmaps/fence > /dev/null 2>&1; then
  g3kubectl get configmaps/fence -o json | jq -r '.data["user.yaml"]' > apis_configs/user.yaml
else
  g3kubectl get configmaps/userapi -o json | jq -r '.data["user.yaml"]' > apis_configs/user.yaml
fi

if g3kubectl get secrets/indexd-secret > /dev/null 2>&1; then
  g3kubectl get secrets/indexd-secret -o json | jq -r '.data["local_settings.py"]' | base64 --decode > apis_configs/indexd_settings.py
  indexdDbPassword=$(grep ^psw apis_configs/indexd_settings.py | awk '{ print $3 }' | sed "s/^'//" | sed "s/'\$//")
  indexdDbSchema=$(grep ^db apis_configs/indexd_settings.py | awk '{ print $3 }' | sed "s/^'//" | sed "s/'\$//")
fi

fencePyFile=""
if g3kubectl get secrets/fence-config > /dev/null 2>&1; then
  fencePyFile=apis_configs/fence-config.yaml
  g3kubectl get secrets/fence-config -o json | jq -r '.data["fence-config.yaml"]' | base64 --decode > "${fencePyFile}"
elif g3kubectl get secrets/userapi-secret > /dev/null 2>&1; then
  fencePyFile=apis_configs/userapi_settings.py
  g3kubectl get secrets/userapi-secret -o json | jq -r '.data["local_settings.py"]' | base64 --decode > "${fencePyFile}"
fi

# TODO may need to update these
if [[ ! -z "${fencePyFile}" ]]; then
  fenceDbUser=$(grep ^DB ${fencePyFile} | sed 's@^.*postgresql://@@' | sed 's/:.*$//')
  fenceDbPassword=$(grep ^DB ${fencePyFile} | sed "s/^.*_user://" | sed 's/@.*$//')
  fenceDbSchema=$(grep ^DB ${fencePyFile} | sed 's@^.*5432/@@' | sed "s/'\$//")
  googleClientId=$(grep client_id ${fencePyFile} | sed "s/.*:\s*//" | sed "s/[', ]*//g")
  googleClientSecret=$(grep client_secret ${fencePyFile} | sed "s/.*:\s*//" | sed "s/[', ]*//g")
fi

amanuensisPyFile=""
if g3kubectl get secrets/amanuensis-config > /dev/null 2>&1; then
  amanuensisPyFile=apis_configs/amanuensis-config.yaml
  g3kubectl get secrets/amanuensis-config -o json | jq -r '.data["amanuensis-config.yaml"]' | base64 --decode > "${amanuensisPyFile}"
fi

# TODO may need to update these
if [[ ! -z "${amanuensisPyFile}" ]]; then
  amanuensisDbUser=$(grep ^DB ${amanuensisPyFile} | sed 's@^.*postgresql://@@' | sed 's/:.*$//')
  amanuensisDbPassword=$(grep ^DB ${amanuensisPyFile} | sed "s/^.*_user://" | sed 's/@.*$//')
  amanuensisDbSchema=$(grep ^DB ${amanuensisPyFile} | sed 's@^.*5432/@@' | sed "s/'\$//")

  dataReleaseBucket=$(grep ^DB ${amanuensisPyFile} | sed 's@^.*5432/@@' | sed "s/'\$//")
  dataReleaseAwsId=$(grep ^DB ${amanuensisPyFile} | sed 's@^.*5432/@@' | sed "s/'\$//")
  dataReleaseAwsSecret=$(grep ^DB ${amanuensisPyFile} | sed 's@^.*5432/@@' | sed "s/'\$//")
fi


if g3kubectl get secrets/sheepdog-secret > /dev/null 2>&1; then
  g3kubectl get secrets/sheepdog-secret -o json | jq -r '.data["wsgi.py"]' | base64 --decode > apis_configs/sheepdog_settings.py
  gdcapiDbUser="sheepdog"
  sheepdogDbPassword=$(grep password apis_configs/sheepdog_settings.py | awk '{ print $2 }' | sed 's/,$//' | sed 's/"//g')
  gdcapiDbPassword="$sheepdogDbPassword"
  gdcapiDbSchema=$(grep database apis_configs/sheepdog_settings.py | awk '{ print $2 }' | sed 's/,$//' | sed 's/"//g')
  gdcapiIndexdSecret=$(grep "'auth'" apis_configs/sheepdog_settings.py | sed "s/^.*'gdcapi', '//" | sed "s/').*\$//")
fi

if g3kubectl get secrets/gdcapi-secret > /dev/null 2>&1; then
  g3kubectl get secrets/gdcapi-secret -o json | jq -r '.data["wsgi.py"]' | base64 --decode > apis_configs/gdcapi_settings.py
  gdcapiDbUser="gdcapi_user"
  gdcapiDbPassword=$(grep password apis_configs/gdcapi_settings.py | awk '{ print $2 }' | sed 's/,$//' | sed 's/"//g')
  gdcapiDbSchema=$(grep database apis_configs/gdcapi_settings.py | awk '{ print $2 }' | sed 's/,$//' | sed 's/"//g')
  gdcapiIndexdSecret=$(grep "'auth'" apis_configs/gdcapi_settings.py | sed "s/^.*'gdcapi', '//" | sed "s/').*\$//")
fi

if g3kubectl get secrets/peregrine-secret > /dev/null 2>&1; then
  g3kubectl get secrets/peregrine-secret -o json | jq -r '.data["wsgi.py"]' | base64 --decode > apis_configs/peregrine_settings.py
  peregrineDbPassword=$(grep password apis_configs/peregrine_settings.py | awk '{ print $2 }' | sed 's/,$//' | sed 's/"//g')
fi

# ok - got all our db passwords now!  let's generate some output files
#
# creds.json is consumed by automation to generate k8s configmaps and secrets
# use terraform to generate creds.json if possible
#
cat - > creds.json <<EOM
{
    "fence": {
        "db_host": "",
        "db_username": "${fenceDbUser}",
        "db_password": "${fenceDbPassword}",
        "db_database": "${fenceDbSchema}",
        "hostname": "",
        "google_client_secret": "${googleClientSecret}",
        "google_client_id": "${googleClientId}",
        "hmac_key": ""
    },
    "amanuensis": {
        "db_host": "",
        "db_username": "${amanuensisDbUser}",
        "db_password": "${amanuensisDbPassword}",
        "db_database": "${amanuensisDbSchema}",
        "hostname": "",
        "data_delivery_bucket": "${dataReleaseBucket}",
        "data_delivery_bucket_aws_key_id": "${dataReleaseAwsId}",
        "data_delivery_bucket_aws_access_key": "${dataReleaseAwsSecret}"
    },
    "userapi": {
        "db_host": "",
        "db_username": "${fenceDbUser}",
        "db_password": "${fenceDbPassword}",
        "db_database": "${fenceDbSchema}",
        "hostname": "${hostname}",
        "google_client_secret": "${googleClientSecret}",
        "google_client_id": "${googleClientId}",
        "hmac_key": ""
    },
    "sheepdog": {
        "fence_host": "",
        "fence_username": "${fenceDbUser}",
        "fence_password": "${fenceDbPassword}",
        "fence_database": "${fenceDbSchema}",
        "db_host": "",
        "db_username": "sheepdog",
        "db_password": "${sheepdogDbPassword}",
        "db_database": "${gdcapiDbSchema}",
        "gdcapi_secret_key": "",
        "indexd_password": "${gdcapiIndexdSecret}",
        "hostname": "${hostname}",
        "oauth2_client_id": "",
        "oauth2_client_secret": ""
    },
    "pcdcanalysistools": {
        "fence_host": "",
        "fence_username": "${fenceDbUser}",
        "fence_password": "${fenceDbPassword}",
        "fence_database": "${fenceDbSchema}",
        "db_host": "",
        "db_username": "sheepdog",
        "db_password": "${sheepdogDbPassword}",
        "db_database": "${gdcapiDbSchema}",
        "gdcapi_secret_key": "",
        "indexd_password": "${gdcapiIndexdSecret}",
        "hostname": "${hostname}",
        "oauth2_client_id": "",
        "oauth2_client_secret": ""
    },
    "peregrine": {
        "fence_host": "",
        "fence_username": "${fenceDbUser}",
        "fence_password": "${fenceDbPassword}",
        "fence_database": "${fenceDbSchema}",
        "db_host": "",
        "db_username": "peregrine",
        "db_password": "${peregrineDbPassword}",
        "db_database": "${gdcapiDbSchema}",
        "gdcapi_secret_key": "",
        "hostname": "${hostname}"
    },
    "gdcapi": {
        "fence_host": "${fence_host}",
        "fence_username": "${fenceDbUser}",
        "fence_password": "${fenceDbPassword}",
        "fence_database": "${fenceDbSchema}",
        "db_host": "",
        "db_username": "${gdcapiDbUser}",
        "db_password": "${gdcapiDbPassword}",
        "db_database": "${gdcapiDbSchema}",
        "gdcapi_secret_key": "",
        "indexd_password": "${gdcapiIndexdSecret}",
        "hostname": "${hostname}",
        "oauth2_client_id": "",
        "oauth2_client_secret": ""
    },
    "indexd": {
        "db_host": "",
        "db_username": "indexd_user",
        "db_password": "${indexdDbPassword}",
        "db_database": "${indexdDbSchema}"
    },
    "gearbox-middleware": {}
}
EOM

#
# config.tfvars is consumed by terraform
#
cat - > config.tfvars <<EOM
# VPC name is also used in DB name, so only alphanumeric characters
vpc_name="$vpcName"
dictionary_url="$dictionaryUrl"

aws_cert_name="${hostname}"

db_size=10

hostname="${hostname}"

google_client_secret="${googleClientSecret}"
google_client_id="${googleClientId}"

# Following variables can be randomly generated passwords

hmac_encryption_key="$(random_alphanumeric 32 | base64)"

gdcapi_secret_key="$(random_alphanumeric 50)"

# don't use ( ) " ' { } < > @ in password
db_password_fence="${fenceDbPassword}"
db_password_amanuensis="${amanuensisDbPassword}"
db_password_gdcapi="${gdcapiDbPassword}"
db_password_sheepdog="${sheepdogDbPassword}"
db_password_peregrine="${peregrineDbPassword}"
db_password_indexd="${indexdDbPassword}"

db_instance="db.t2.micro"

# password for write access to indexd
gdcapi_indexd_password="${gdcapiIndexdSecret}"

amanuensis_snapshot=""
fence_snapshot=""
gdcapi_snapshot=""
indexd_snapshot=""

# slack webhook for alarms
slack_webhook=""

# ssh key to be added to kube nodes
kube_ssh_key=""

kube_additional_keys = <<EOB
  - '"ssh-dss AAAAB3NzaC1kc3MAAACBAPfnMD7+UvFnOaQF00Xn636M1IiGKb7XkxJlQfq7lgyzWroUMwXFKODlbizgtoLmYToy0I4fUdiT4x22XrHDY+scco+3aDq+Nug+jaKqCkq+7Ms3owtProd0Jj6AWCFW+PPs0tGJiObieci4YqQavB299yFNn+jusIrDsqlrUf7xAAAAFQCi4wno2jigjedM/hFoEFiBR/wdlwAAAIBl6vTMb2yDtipuDflqZdA5f6rtlx4p+Dmclw8jz9iHWmjyE4KvADGDTy34lhle5r3UIou5o3TzxVtfy00Rvyd2aa4QscFiX5jZHQYnbIwwlQzguCiF/gtYNCIZit2B+R1p2XTR8URY7CWOTex4X4Lc88UEsM6AgXIpJ5KKn1pK2gAAAIAJD8p4AeJtnimJTKBdahjcRdDDedD3qTf8lr3g81K2uxxsLOudweYSZ1oFwP7RnZQK+vVE8uHhpkmfsy1wKCHrz/vLFAQfI47JDX33yZmBLtHjjfmYDdKVn36XKZ5XrO66vcbX2Jav9Hlqb6w/nekBx2nbJaZnHwlAp70RU13gyQ== renukarya@Renukas-MacBook-Pro.local"'
EOB
EOM
