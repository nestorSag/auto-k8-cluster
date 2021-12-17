"""Generates an Ansible inventory file from terraform's output json

"""
import sys
from utils import get_node_ips

ips = get_node_ips(sys.stdin)

hostfile_content = ""
for nodeset in ("worker", "controller"):
  node_ips = ips[nodeset]
  node_ids = sorted(node_ips.keys())
  node_lines = [
  "{nodeset}-{idx} ansible_host={ip}".format(
    nodeset=nodeset,
    idx=idx,
    ip=node_ips[node]["public_ip"]) for idx, node in enumerate(node_ids)
  ]
  hostfile_content += "\n[{nodeset}]\n{lines}".format(nodeset=nodeset, lines="\n".join(node_lines))

with open("./ansible/hosts", "w") as f:
  f.write(hostfile_content)

