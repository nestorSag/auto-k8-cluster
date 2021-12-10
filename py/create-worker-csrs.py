"""Takes a json-formatted terraform output and creates certificate signing requests for each worker node. The filenames are the full hostnames passed to cfssl for each instance.

"""
import json
import sys
import os
from pathlib import Path


# reset output folder
outfolder = Path("./pki/worker-csrs")
outfolder.mkdir(parents=True, exist_ok=True)
for file in outfolder.iterdir():
  os.remove(file)

# parse terraform output
ip_json = json.load(sys.stdin)
public = ip_json["worker-public-ips"]["value"]
private = ip_json["worker-private-ips"]["value"]
nodes = sorted(public.keys())
# create worker keys
for idx, node in enumerate(nodes):
  hostname = f"worker-{idx}"
  public_ip = public[node]
  private_ip = private[node]
  hostname_str = f"{hostname},{public_ip},{private_ip}"
  # read csr and interpolate instance name
  with open("pki/config/worker-template.json","r") as f:
    csr_str = json.loads(f.read())
    csr_str["CN"] = csr_str["CN"].replace("INSTANCE_NAME", hostname)
  # save interpolated csr file
  csr_file = str(outfolder / hostname_str)
  with open(csr_file,"w") as f:
    json.dump(csr_str, f, indent=2)

