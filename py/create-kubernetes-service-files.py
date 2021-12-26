"""Generates kubernetes and proxy nginx service unit files from Terraform's json output

"""
import os
import sys
from pathlib import Path
from utils import get_node_ips, get_lb_dns

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
  server_name = "https://{private_ip}:2379".format(
    idx=idx, 
    private_ip=controllers[node]["private_ip"])
  etcd_servers.append(server_name)
etcd_servers = ",".join(etcd_servers)

# count number of API servers
n_servers = len(node_ids)

# get LB DNS
lb_dns = get_lb_dns(tf_json)

# create unit file for each etcd node
for idx, node in enumerate(node_ids):
  name = "controller-{idx}".format(idx=idx)
  internal_ip = controllers[node]["private_ip"]
  # create kube-apiserver file
  with open(Path("service-templates") / "kube-apiserver.service", "r") as f:
    service_file = f.read().format(
      ETCD_SERVERS=etcd_servers,
      INTERNAL_IP=internal_ip,
      N_SERVERS=n_servers,
      LB_DNS=lb_dns)
  with open(outfolder / "kube-apiserver-controller-{idx}.service".format(idx=idx), "w") as f:
    f.write(service_file)

# copy additional config files from template folder to service file folder
files = [
  "kube-controller-manager.service",
  "kube-scheduler.service"] # nginx health check server file

for fl in files:
  with open(Path("service-templates") / fl) as f:
    service_file = f.read()
  with open(outfolder / fl, "w") as f:
    f.write(service_file)
