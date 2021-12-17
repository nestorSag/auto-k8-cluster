"""Utilities to parse terraform output strings

"""
import typing as t
import json
import sys
import os

def get_node_ips(tf_output: str):
  """Parse terraform json output into a dictionary of node ip addresses
  
  Args:
      tf_output (str): terraform output
  
  Returns:
      dict: dictionary with 'worker' and 'controller' keys.
  """
  formatted = {}
  # parse terraform output
  tf_json = json.load(tf_output)
  for nodeset in ("worker", "controller"):
    nodes = tf_json["{type}-public-ips".format(type=nodeset)]["value"].keys()
    formatted[nodeset] = {
      node: {
      "public_ip": tf_json["{type}-public-ips".format(type=nodeset)]["value"][node], 
      "private_ip": tf_json["{type}-private-ips".format(type=nodeset)]["value"][node]
      } for node in nodes
    }
  return formatted
