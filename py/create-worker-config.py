"""Generates kubernetes and networking configuration files for worker nodes

"""
import os
import sys
from pathlib import Path
from utils import get_node_ips

# read stdin as string (which allows to reuse it if needed)
with sys.stdin as f:
  tf_json = f.read()

ips = get_node_ips(tf_json)
workers = ips["worker"]
node_ids = sorted(controllers.keys())

# create kubelet config yaml file
for idx, node in enumerate(node_ids):
  pod_cidr = f"10.200.{idx}.0/24"
  hostname = f"worker-{idx}"
  with open(Path("pki") / "config" / "kubelet-config.yaml", "r") as f:
    service_file = f.read().format(
      HOSTNAME=hostname,
      POD_CIDR=pod_cidr)
  with open(Path("kubeyaml") / "kubelet-config-{hostname}.yaml".format(hostname=hostname), "w") as f:
    f.write(service_file)

  with open(Path("network-conf-templates") / "10-bridge.conf", "r") as f:
    network_conf = f.read().format(
      POD_CIDR=pod_cidr)
  with open("network-conf" / "10-bridge-{hostname}.conf".format(hostname=hostname), "w") as f:
    f.write(service_file)