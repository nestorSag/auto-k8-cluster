"""Takes a json-formatted terraform output and creates certificate signing requests for each worker node. The filenames are the full hostnames passed to cfssl for each instance.

"""
import os 
import sys
import json
from pathlib import Path
from utils import get_node_ips

# reset output folder
outfolder = Path("./pki/worker-csrs")
outfolder.mkdir(parents=True, exist_ok=True)
for file in outfolder.iterdir():
  os.remove(file)

worker_ips = get_node_ips(sys.stdin)["worker"]
worker_ids = sort(worker_ips.keys()) #sort to impose a consistent ordering between hostname and ips

# create worker keys
for idx, node in enumerate(worker_ids):
  hostname = f"worker-{idx}"
  public_ip = worker_ips[node]["public_ip"]
  private_ip = worker_ips[node]["private_ip"]
  hostname_str = f"{hostname},{public_ip},{private_ip}"

  # read csr and interpolate instance name
  with open("pki/config/worker-template.json","r") as f:
    csr_str = json.loads(f.read())
    csr_str["CN"] = csr_str["CN"].replace("INSTANCE_NAME", hostname)
    
  # save interpolated csr file
  csr_file = str(outfolder / hostname)
  with open(csr_file,"w") as f:
    json.dump(csr_str, f, indent=2)

