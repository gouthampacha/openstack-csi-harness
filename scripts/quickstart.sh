#!/usr/bin/env bash
# openstack-csi-harness quickstart
# Usage: ./scripts/quickstart.sh <command> [profile]
#
# Commands:
#   setup <profile>     - Full stack: VM + DevStack + k3s + CSI + e2e
#   vm-create           - Create the DevStack VM
#   vm-destroy          - Destroy the DevStack VM
#   devstack <profile>  - Install DevStack with the given profile
#   k3s                 - Install k3s on the DevStack VM
#   deploy <profile>    - Build and deploy CSI driver
#   e2e                 - Run e2e tests
#   logs                - Fetch logs from the VM
#
# Profiles: manila-lvm, manila-cephfs-nfs, manila-cephfs-native, cinder-lvm, cinder-rbd
#
# Examples:
#   ./scripts/quickstart.sh setup manila-lvm
#   ./scripts/quickstart.sh deploy cinder-rbd
#   ./scripts/quickstart.sh e2e

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    sed -n '2,/^$/s/^# //p' "$0"
    exit 1
}

run_playbook() {
    local playbook="$1"
    shift
    ansible-playbook "${SCRIPT_DIR}/playbooks/${playbook}" "$@"
}

[[ $# -lt 1 ]] && usage

CMD="$1"
PROFILE="${2:-}"

case "$CMD" in
    setup)
        [[ -z "$PROFILE" ]] && { echo "Error: profile required"; usage; }
        run_playbook setup.yml -e "@${SCRIPT_DIR}/profiles/${PROFILE}.yml"
        ;;
    vm-create)
        run_playbook vm-create.yml
        ;;
    vm-destroy)
        run_playbook vm-destroy.yml
        ;;
    devstack)
        [[ -z "$PROFILE" ]] && { echo "Error: profile required"; usage; }
        run_playbook devstack.yml -e "@${SCRIPT_DIR}/profiles/${PROFILE}.yml"
        ;;
    k3s)
        run_playbook k3s.yml
        ;;
    deploy)
        [[ -z "$PROFILE" ]] && { echo "Error: profile required"; usage; }
        run_playbook deploy-csi.yml -e "@${SCRIPT_DIR}/profiles/${PROFILE}.yml"
        ;;
    e2e)
        run_playbook e2e.yml
        ;;
    logs)
        run_playbook fetch-logs.yml
        ;;
    *)
        echo "Unknown command: $CMD"
        usage
        ;;
esac
