"""Takes a json-formatted terraform output as std input and creates certificate signing requests for each worker node

"""
import os 
import sys
import json
from pathlib import Path
from utils import get_node_ips

# reset output folder
outfolder = Path("pki") / "worker-csrs"
outfolder.mkdir(parents=True, exist_ok=True)
for file in outfolder.iterdir():
  os.remove(file)

# read stdin as string (which allows to reuse it if needed)
with sys.stdin as f:
  tf_json = f.read()

worker_ips = get_node_ips(tf_json)["worker"]
worker_ids = sorted(worker_ips.keys()) #sort to impose a consistent ordering between hostname and ips

# create worker csrs
for idx, node in enumerate(worker_ids):
  hostname = f"worker-{idx}"
  public_ip = worker_ips[node]["public_ip"]
  private_ip = worker_ips[node]["private_ip"]
  #hostname_str = f"{hostname},{public_ip},{private_ip}"

  # read csr template and add instance hostnames
  with open(Path("pki") / "config" / "worker-csr-template.json","r") as f:
    worker_csr = json.loads(f.read())
    worker_csr["CN"] = "system:node:{cn}".format(cn=hostname) #csr_str["CN"].replace("INSTANCE_NAME", hostname)
    worker_csr["hosts"] = [hostname, public_ip, private_ip]
    
  # save interpolated csr file
  csr_file = str(outfolder / (hostname + ".json"))
  with open(csr_file,"w") as f:
    json.dump(worker_csr, f, indent=2)

