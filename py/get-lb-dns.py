"""Takes a json-formatted terraform output as std input and outputs the load balancer's DNS

"""
import sys
from utils import get_lb_dns

# read stdin as string (which allows to reuse it if needed)
with sys.stdin as f:
  tf_json = f.read()

print(get_lb_dns(tf_json))