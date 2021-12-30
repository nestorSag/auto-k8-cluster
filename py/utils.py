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
      dict: dictionary with 'worker' and 'controller' keys. Each is a dict with schema {'node0': {'private_ip': X, 'public_ip': Y}, ...}
  """
  formatted = {}
  # parse terraform output
  tf_json = json.loads(tf_output)
  for nodeset in ("worker", "controller"):
    nodes = tf_json["{type}-public-ips".format(type=nodeset)]["value"].keys()
    formatted[nodeset] = {
      node: {
      "public_ip": tf_json["{type}-public-ips".format(type=nodeset)]["value"][node], 
      "private_ip": tf_json["{type}-private-ips".format(type=nodeset)]["value"][node]
      } for node in nodes
    }
  return formatted

def get_lb_dns(tf_output: str):
  """Parse terraform json output and returns the ELB's DNS
  
  Args:
      tf_output (str): terraform output
  
  Returns:
      str: DNS string
  """
  formatted = {}
  # parse terraform output
  tf_json = json.loads(tf_output)
  dns = tf_json["lb-dns"]["value"]
  return dns

def get_rt_id(tf_output: str):
  """Parse terraform json output and returns the main routing table's id
  
  Args:
      tf_output (str): terraform output
  
  Returns:
      str: routing table id
  """
  formatted = {}
  # parse terraform output
  tf_json = json.loads(tf_output)
  tbl_id = tf_json["routing-table-id"]["value"]
  return tbl_id
