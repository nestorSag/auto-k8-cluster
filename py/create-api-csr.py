"""Takes a json-formatted terraform output as std input and creates certificate signing requests for the Kubernetes API

"""
import os 
import sys
import json
from pathlib import Path
from utils import get_lb_dns, get_node_ips

# reset output folder
outfolder = Path("pki") / "api-csr"
outfolder.mkdir(parents=True, exist_ok=True)
for file in outfolder.iterdir():
  os.remove(file)

# list all hostnames
k8_hostnames = [
  "kubernetes",
  "kubernetes.default",
  "kubernetes.default.svc",
  "kubernetes.default.svc.cluster",
  "kubernetes.svc.cluster.local",
  "kubernetes.default.svc.cluster.local"
]

# read stdin as string (which allows to reuse it if needed)
with sys.stdin as f:
  tf_json = f.read()

lb_dns = get_lb_dns(tf_json)
intracluster_api_ip = "10.32.0.1"
localhost_ip="127.0.0.1"

controllers = get_node_ips(tf_json)["controller"]

private_controller_ips = [controllers[node]["private_ip"] for node in controllers]

# open and fill template
with open(Path("pki") / "config" / "api-csr-template.json","r") as f:
  api_csr = json.loads(f.read())
  api_csr["hosts"] = k8_hostnames + [lb_dns, intracluster_api_ip, localhost_ip] + private_controller_ips
  
# save interpolated csr file
csr_file = str(outfolder / "api-csr.json")
with open(csr_file,"w") as f:
  json.dump(api_csr, f, indent=2)
