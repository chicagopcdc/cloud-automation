#!/bin/bash
#
# Deploy the metdata service.
#

source "${GEN3_HOME}/gen3/lib/utils.sh"
gen3_load "gen3/gen3setup"


setup_gearbox_middle() {
  if g3kubectl describe secret gearbox-middleware-g3auto > /dev/null 2>&1; then
    gen3_log_info "gearbox-middleware-g3auto secret already configured"
    return 0
  fi
  
  if [[ ! -f "$secretsFolder/gearbox-middleware.env" || ! -f "$secretsFolder/base64Authz.txt" ]]; then
    local secretsFolder="$(gen3_secrets_folder)/g3auto/gearbox-middleware"
    # go ahead and rotate the password whenever we regen this file
    local password="$(gen3 random)"
    cat - > "$secretsFolder/gearbox-middleware.env" <<EOM

ADMIN_LOGINS=gateway:$password
EOM
    # make it easy for nginx to get the Authorization header ...
    echo -n "gateway:$password" | base64 > "$secretsFolder/base64Authz.txt"
  fi
  gen3 secrets sync 'setup gearbox-middleware-g3auto secrets'
}

if ! g3k_manifest_lookup .versions.gearbox-middleware 2> /dev/null; then
  gen3_log_info "kube-setup-gearbox-middleware exiting - gearbox-middleware service not in manifest"
  exit 0
fi

if ! setup_gearbox_middle; then
  gen3_log_err "kube-setup-gearbox-middleware bailing out - secrets failed setup"
  exit 1
fi


gen3 roll gearbox-middleware
g3kubectl apply -f "${GEN3_HOME}/kube/services/gearbox-middleware/gearbox-middlware-service.yaml"

if [[ -z "$GEN3_ROLL_ALL" ]]; then
  gen3 kube-setup-networkpolicy
  gen3 kube-setup-revproxy
fi

gen3_log_info "The gearbox service has been deployed onto the kubernetes cluster"
gen3_log_info "test with: curl https://commons-host/gearbox-match/_status"
