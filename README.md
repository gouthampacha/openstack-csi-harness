# openstack-csi-harness

Test harness for OpenStack CSI drivers (Manila CSI and Cinder CSI) using
DevStack, Ansible, and k3s.

Creates a DevStack VM on a libvirt hypervisor, installs k3s, builds and deploys
a CSI driver from your local source, and runs e2e tests — all via Ansible
playbooks.

## Prerequisites

- A Linux machine with libvirt/KVM (`virt-install`, `virsh`)
- Ansible 2.14+ on your workstation
- A clone of [cloud-provider-openstack](https://github.com/kubernetes/cloud-provider-openstack)
- SSH key pair for VM access
- Docker (if building CSI images locally)

## Quick start

```bash
# 1. Copy and edit the inventory
cp inventory/hosts.example inventory/hosts
# Edit inventory/hosts with your hypervisor address, SSH key path, and CPO source dir

# 2. Full setup with Manila LVM
./scripts/quickstart.sh setup manila-lvm

# Or step by step:
./scripts/quickstart.sh vm-create
./scripts/quickstart.sh devstack manila-lvm
./scripts/quickstart.sh k3s
./scripts/quickstart.sh deploy manila-lvm
./scripts/quickstart.sh e2e
```

## Backend profiles

| Profile | CSI Driver | Storage Backend | Share Protocol |
|---|---|---|---|
| `manila-lvm` | Manila CSI | LVM (NFS shares) | NFS |
| `manila-cephfs-nfs` | Manila CSI | CephFS via NFS-Ganesha | NFS |
| `manila-cephfs-native` | Manila CSI | Native CephFS | CEPHFS |
| `cinder-lvm` | Cinder CSI | LVM | Block |
| `cinder-rbd` | Cinder CSI | Ceph RBD | Block |

Profiles are YAML files in `profiles/`. Load them with `-e @profiles/<name>.yml`
or via the quickstart script.

## Playbooks

| Playbook | Description |
|---|---|
| `setup.yml` | Full stack: VM + DevStack + k3s + CSI + e2e |
| `vm-create.yml` | Create a DevStack VM on the hypervisor |
| `vm-destroy.yml` | Destroy the VM and clean up storage |
| `devstack.yml` | Install DevStack on an existing VM |
| `k3s.yml` | Install k3s and a Docker registry |
| `deploy-csi.yml` | Build CSI image and deploy via Helm |
| `e2e.yml` | Run e2e tests |
| `fetch-logs.yml` | Collect logs from the VM |

Run any playbook directly:

```bash
ansible-playbook playbooks/devstack.yml -e @profiles/cinder-rbd.yml
```

## Inventory

Copy `inventory/hosts.example` to `inventory/hosts` (gitignored) and fill in:

- **hypervisor**: your libvirt host
- **devstack**: the VM (auto-populated by `vm-create`, or set manually)
- **cpo_source_dir**: path to your cloud-provider-openstack clone
- **ssh_public_key**: SSH public key to inject into the VM

## CSI image build

By default, images are built on your local workstation and pushed to a
self-signed Docker registry on the VM. Set `build_on_vm: true` to build
directly on the VM instead:

```bash
ansible-playbook playbooks/deploy-csi.yml -e @profiles/manila-lvm.yml -e build_on_vm=true
```

## Known limitations

**Cinder CSI requires OpenStack VMs**: The Cinder CSI node plugin calls the
OpenStack metadata service (169.254.169.254) to get the instance UUID, which is
needed for volume attachment via the Nova API. Since this harness runs k3s
directly on a libvirt VM (not a Nova instance), Cinder CSI pods will deploy but
volume attachment will fail. Full Cinder CSI e2e testing requires running k3s
inside a Nova VM within DevStack. Manila CSI does not have this limitation since
it mounts NFS/CephFS shares without needing a Nova instance identity.

## Configuration

Default variables are in `group_vars/all.yml`. Override with `-e` flags or by
editing profile files.

| Variable | Default | Description |
|---|---|---|
| `devstack_branch` | `stable/2025.2` | OpenStack release branch |
| `k3s_version` | `v1.32.5+k3s1` | k3s version |
| `vm_vcpus` | `8` | VM CPU count |
| `vm_memory_mb` | `32768` | VM memory (MB) |
| `vm_disk_gb` | `200` | VM disk size (GB) |
| `csi_image_version` | `v0.0.99` | CSI image tag |
| `build_on_vm` | `false` | Build image on VM instead of locally |
| `container_engine` | `docker` | Container engine (`docker` or `podman`) |
| `e2e_timeout` | `1h45m` | e2e test timeout |

## Fetching logs

```bash
./scripts/quickstart.sh logs
# Logs saved to ./logs/<hostname>/
```

Collects: DevStack logs, k3s journal, CSI pod logs, and e2e test results.

## Cleanup

```bash
./scripts/quickstart.sh vm-destroy
```
