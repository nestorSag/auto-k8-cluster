"""Generates etcd service unit files from Terraform's json output

"""
import os
import sys
from pathlib import Path
from utils import get_node_ips

outfolder = Path("services")

# read stdin as string (which allows to reuse it if needed)
with sys.stdin as f:
  tf_json = f.read()

ips = get_node_ips(tf_json)
controllers = ips["controller"]
node_ids = sorted(controllers.keys())

# create etcd server name list string
etcd_servers = []
for idx, node in enumerate(node_ids):
  server_name = "controller-{idx}=https://{private_ip}:2380".format(
    idx=idx, 
    private_ip=controllers[node]["private_ip"])
  etcd_servers.append(server_name)
etcd_servers = ",".join(etcd_servers)

# create unit file for each etcd node
for idx, node in enumerate(node_ids):
  name = "controller-{idx}".format(idx=idx)
  internal_ip = controllers[node]["private_ip"]
  with open(Path("service-templates") / "etcd.service", "r") as f:
    service_file = f.read().format(
      ETCD_NAME=name,
      INTERNAL_IP=internal_ip,
      ETCD_SERVERS=etcd_servers)
  with open(outfolder / "etcd-controller-{idx}.service".format(idx=idx), "w") as f:
    f.write(service_file)



