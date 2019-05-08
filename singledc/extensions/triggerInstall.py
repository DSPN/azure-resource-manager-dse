#!/usr/bin/python
import argparse
import requests
import utilLCM as lcm

def setupArgs():
    parser = argparse.ArgumentParser(description='Trigger LCM install job after last node posts.',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    required = parser.add_argument_group('Required named arguments')
    parser.add_argument('--opsc-ip', type=str, default='127.0.0.1',
                        help='IP of OpsCenter instance (or FQDN)')
    parser.add_argument('--opscuser', type=str, default='admin', help='opscenter admin user')
    parser.add_argument('--opscpw', type=str, default='admin', help='password for opscuser')
    required.add_argument('--clustername', required=True, type=str, help='Name of cluster.')
    required.add_argument('--clustersize', type=int,
                          help='Trigger install job when clustersize nodes have posted')
    parser.add_argument('--dclevel', action='store_true', help='Trigger DC level install job(s).')
    parser.add_argument('--pause', type=int, default=6,
                        help="pause time (sec) between attempts to contact OpsCenter")
    parser.add_argument('--trys', type=int, default=200,
                        help="number of times to attempt to contact OpsCenter")
    return parser

def main():
    parser = setupArgs()
    args = parser.parse_args()

    opsc = lcm.OpsCenter(args.opsc_ip, args.opscuser, args.opscpw)
    # Block waiting for OpsC to spin up, create session & login if needed
    opsc.setupSession(pause=args.pause, trys=args.trys)

    opsc.waitForCluster(cname=args.clustername, pause=args.pause, trys=args.trys) # Block until cluster created
    clusters = opsc.session.get("{url}/api/v2/lcm/clusters/".format(url=opsc.url)).json()
    for r in clusters['results']:
        if r['name'] == args.clustername:
            cid = r['id']
    opsc.waitForNodes(numnodes=args.clustersize, pause=args.pause, trys=args.trys)
    if args.dclevel:
        datacenters = opsc.session.get("{url}/api/v2/lcm/datacenters/".format(url=opsc.url)).json()
        for r in datacenters['results']:
            dcid = r['id']
            print "Triggering install for DC, id = {i}".format(i=dcid)
            opsc.triggerInstall(None, dcid)
    else:
        print "Triggering install for cluster, id = {i}".format(i=cid)
        opsc.triggerInstall(cid, None)

# ----------------------------
if __name__ == "__main__":
    main()
