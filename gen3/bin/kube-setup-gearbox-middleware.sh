#!/bin/bash
#
# Deploy the metdata service.
#

source "${GEN3_HOME}/gen3/lib/utils.sh"
gen3_load "gen3/gen3setup"

gen3 roll gearbox-middleware
g3kubectl apply -f "${GEN3_HOME}/kube/services/gearbox-middleware/gearbox-middlware-service.yaml"

cat <<EOM
The gearbox-middleware service has been deployed onto the k8s cluster.
EOM