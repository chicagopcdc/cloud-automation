#!/bin/bash
#
# Deploy amanuensis into existing commons - assume configs are already configured
# for amanuensis to re-use the userapi db.
# This fragment is pasted into kube-services.sh by kube.tf.
#

source "${GEN3_HOME}/gen3/lib/utils.sh"
gen3_load "gen3/lib/kube-setup-init"

gen3 update_config amanuensis-yaml-merge "${GEN3_HOME}/apis_configs/yaml_merge.py"
[[ -z "$GEN3_ROLL_ALL" ]] && gen3 kube-setup-secrets

if [[ -f "$(gen3_secrets_folder)/creds.json" && -z "$JENKINS_HOME" ]]; then # create database
  # Initialize amanuensis database and user list
  cd "$(gen3_secrets_folder)"
  if [[ ! -f .rendered_amanuensis_db ]]; then
    gen3 job run amanuensisdb-create
    gen3_log_info "Waiting 10 seconds for amanuensisdb-create job"
    sleep 10
    gen3 job logs amanuensisdb-create || true
    gen3_log_info "Leaving setup jobs running in background"
  fi
  # avoid doing the previous block more than once or when not necessary ...
  touch "$(gen3_secrets_folder)/.rendered_amanuensis_db"
fi

# run db migration job - disable, because this still causes locking in dcf 
if false; then
  gen3_log_info "Launching db migrate job"
  gen3 job run amanuensis-db-migrate -w || true
  gen3 job logs amanuensis-db-migrate -f || true
fi

# deploy amanuensis
gen3 roll amanuensis
g3kubectl apply -f "${GEN3_HOME}/kube/services/amanuensis/amanuensis-service.yaml"

# g3kubectl apply -f "${GEN3_HOME}/kube/services/amanuensis/amanuensis-canary-service.yaml"
gen3_log_info "The amanuensis service has been deployed onto the k8s cluster."

