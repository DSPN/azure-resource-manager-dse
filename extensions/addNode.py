#!/usr/bin/python
import json
import argparse
import requests
import utilLCM as lcm

# fixme
# - addThing methods should return id value, or None with failure


def setupArgs():
    parser = argparse.ArgumentParser(description='Add calling instance to an LCM managed DSE cluster.',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    required = parser.add_argument_group('Required named arguments')
    required.add_argument('--opsc-ip', required=True, type=str,
                          help='IP of OpsCenter instance (or FQDN)')
    parser.add_argument('--opscuser', type=str, default='admin', help='opscenter admin user')
    parser.add_argument('--opscpw', type=str, default='admin', help='password for opscuser')
    required.add_argument('--clustername', required=True, type=str,
                          help='Name of cluster.')
    required.add_argument('--dcname', required=True, type=str, help='Datacenter node belongs to.')
    required.add_argument('--nodeid', required=True, type=str, help='Unique node id.')
    required.add_argument('--privip', required=True, type=str, help='Private ip of node.')
    required.add_argument('--pubip', required=True, type=str, help='Public ip of node.')
    parser.add_argument('--rack', type=str, default='rack0', help='Rack node belongs to.')
    parser.add_argument('--pause', type=int, default=6,
                        help="pause time (sec) between attempts to contact OpsCenter")
    parser.add_argument('--trys', type=int, default=100,
                        help="number of times to attempt to contact OpsCenter")
    parser.add_argument('--verbose', action='store_true', help='Verbose flag, right now a NO-OP.')
    return parser

def main():
    parser = setupArgs()
    args = parser.parse_args()

    opsc = lcm.OpsCenter(args.opsc_ip, args.opscuser, args.opscpw)
    # Block waiting for OpsC to spin up, create session & login if needed
    opsc.setupSession(pause=args.pause, trys=args.trys)
    # Block until cluster created
    opsc.waitForCluster(args.clustername, args.pause, args.trys)

    clusters = opsc.session.get("{url}/api/v2/lcm/clusters/".format(url=opsc.url)).json()
    for r in clusters['results']:
        if r['name'] == args.clustername:
            cid = r['id']

    # Check if the DC --this-- node should belong to exists, if not add DC
    if opsc.checkForDC(args.dcname):
        print "Datacenter {d} exists".format(d=args.dcname)
    else:
        print "Datacenter {n} doesn't exist, creating...".format(n=args.dcname)
        opsc.addDC(args.dcname, cid)

    # kludge, assuming ony one cluster
    dcid = ""
    datacenters = opsc.session.get("{url}/api/v2/lcm/datacenters/".format(url=opsc.url)).json()
    for d in datacenters['results']:
        if d['name'] == args.dcname:
            dcid = d['id']

    # always add self to DC
    nodes = opsc.session.get("{url}/api/v2/lcm/datacenters/{dcid}/nodes/".format(url=opsc.url, dcid=dcid)).json()
    nodecount = nodes['count']
    # simple counting for node number hits a race condition... work around
    #nodename = 'node'+str(nodecount)
    # aws metadata service instance-id
    #inst = requests.get("http://169.254.169.254/latest/meta-data/instance-id").content
    nodename = 'node-'+args.nodeid
    nodeconf = json.dumps({
        'name': nodename,
        "datacenter-id": dcid,
        "rack": args.rack,
        "ssh-management-address": args.pubip,
        "listen-address": args.privip,
        "native-transport-address": "0.0.0.0",
        "broadcast-address": args.pubip,
        "native-transport-broadcast-address": args.pubip})
    node = opsc.session.post("{url}/api/v2/lcm/nodes/".format(url=opsc.url), data=nodeconf).json()
    print "Added node '{n}', json:".format(n=nodename)
    lcm.pretty(node)

    nodes = opsc.session.get("{url}/api/v2/lcm/datacenters/{dcid}/nodes/".format(url=opsc.url, dcid=dcid)).json()
    nodecount = nodes['count']
    print "{n} nodes in datacenter {d}".format(n=nodecount, d=dcid)
    print "Exiting addNode..."

# ----------------------------
if __name__ == "__main__":
    main()
