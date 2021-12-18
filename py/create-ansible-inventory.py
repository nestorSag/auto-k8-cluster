"""Generates an Ansible inventory file from terraform's output json

"""
import sys
from pathlib import Path
from utils import get_node_ips

# read stdin as string (which allows to reuse it if needed)
with sys.stdin as f:
  tf_json = f.read()

ips = get_node_ips(tf_json)

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

with open(Path("ansible") / "hosts", "w") as f:
  f.write(hostfile_content)

