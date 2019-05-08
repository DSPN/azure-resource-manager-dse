#!/usr/bin/python
import json
import argparse
import time
import utilLCM as lcm

def setupArgs():
    info = """Alter system keyspaces to use NetworkTopologyStrategy and RF
    min(3, # nodes)
    NOTE: system, system_schema, dse_system & solr_admin un-altered.
    In DSE 5.1.x, repair all altered keyspaces. If passed --nodesync,
    in DSE 6.0.x enable nodesync for all keyspaces except system_auth
    and OpsCenter and repair those 2 keyspaces.
    """
    parser = argparse.ArgumentParser(description=info,
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--opsc-ip', type=str, default='127.0.0.1',
                        help='IP of OpsCenter instance (or FQDN)')
    parser.add_argument('--opscuser', type=str, default='admin',
                        help='opscenter admin user')
    parser.add_argument('--opscpw', type=str, default='admin',
                        help='password for opscuser')
    parser.add_argument('--pause', type=int, default=6,
                        help="pause time (sec) between attempts to contact OpsCenter")
    parser.add_argument('--trys', type=int, default=20,
                        help="number of times to attempt to contact OpsCenter")
    parser.add_argument('--delay', type=int, default=0,
                        help="number of sec to delay/sleep at start")
    parser.add_argument('--norepair', action='store_true', help='skip repair jobs')
    parser.add_argument('--nodesync', action='store_true', help='enable nodesync')
    parser.add_argument('--verbose', action='store_true', help='verbose flag')
    return parser

def runRepair(opsc, cid, nodes, keyspaces):
    for ks in keyspaces:
        print "Repairing {ks}...".format(ks=ks)
        for node in nodes:
            nodeip = str(node['node_ip'])
            print "    ...on node {n}".format(n=nodeip)
            response = {} #fake response that's non string
            while isinstance(response, dict):
                response = opsc.session.post("{url}/{id}/ops/repair/{node}/{ks}".format(url=opsc.url, id=cid, node=nodeip, ks=ks), data='{"is_sequential": false}').json()
                if isinstance(response, dict):
                    print "Unexpected response: {r}".format(r=response)
                    print "Sleeping 15s..."
                    time.sleep(15)
            print "   ", response
            running = True
            count = 0
            while running:
                print "    Sleeping 5s after check {c}...".format(c=count)
                time.sleep(5)
                status = opsc.session.get("{url}/request/{r}/status".format(url=opsc.url, r=response)).json()
                count += 1
                if 'state' not in status:
                    print "Unexpected status: {s}".format(s=status)
                    print "Retrying..."
                if status['state'] == u'success':
                    print "    Status of request {r} is: {s}".format(r=response, s=status)
                    running = False
                if status['state'] == u'error':
                    print "    Error in request {r} is: {s}".format(r=response, s=status)
                    print "    Rerunning repair..."
                    response = opsc.session.post("{url}/{id}/ops/repair/{node}/{ks}".format(url=opsc.url, id=cid, node=nodeip, ks=ks), data='{"is_sequential": false}').json()
                if count >= 15:
                    print "    Status {s} after {c} checks, continuing".format(s=status['state'], c=count)
                    running = False
    return

def enableNodesync(opsc, cid, keyspaces):
    print "Skipping keyspaces: system_auth, OpsCenter"
    print "Enabling nodesync on keyspaces: {s}".format(s=', '.join(keyspaces))
    data = {"enable": []}
    for k in keyspaces:
        data["enable"].append("{s}.*".format(s=k))
    response = opsc.session.post("{url}/{id}/nodesync".format(url=opsc.url, id=cid), data=json.dumps(data))
    print response
    return

def main():
    parser = setupArgs()
    args = parser.parse_args()

    print "Starting alterKeyspaces: {t}".format(t=time.ctime())
    print "Sleeping {s} sec before start...".format(s=args.delay)
    time.sleep(args.delay)
    opsc = lcm.OpsCenter(args.opsc_ip, args.opscuser, args.opscpw)
    # Block waiting for OpsC to spin up, create session & login if needed
    opsc.setupSession(pause=args.pause, trys=args.trys)

    # get cluster id, assume 1 cluster
    clusterconf = opsc.session.get("{url}/cluster-configs".format(url=opsc.url)).json()
    if len(clusterconf.keys()) == 0:
        print "Error: no clusters, exiting."
        # exiting with 0 as to not propigate error up to deploy
        exit()
    if args.verbose:
        lcm.pretty(clusterconf)
    cid = clusterconf.keys()[0]
    # get all node configs
    nodes = opsc.session.get("{url}/{id}/nodes".format(url=opsc.url, id=cid)).json()
    if len(nodes) == 0:
        print "Error: no nodes, exiting."
        # exiting with 0 as to not propigate error up to deploy
        exit()
    if args.verbose:
        lcm.pretty(nodes)
    # loop of configs, counting nodes in each dc
    datacenters = {}
    for n in nodes:
        if n['dc'] in datacenters:
            datacenters[n['dc']] += 1
        else:
            datacenters[n['dc']] = 1
    # reuse dict for post data in REST call
    # min(3,#) handles edge case where # of nodes < 3
    for d in datacenters:
        datacenters[d] = min(3, datacenters[d])
    # keyspaces to alter
    # leaving out LocalStrategy (system & system_schema) and EverywhereStrategy (dse_system & solr_admin)
    keyspaces = {"system_auth", "system_distributed", "system_traces", "dse_analytics",
                 "dse_security", "dse_perf", "dse_leases", "cfs_archive",
                 "spark_system", "cfs", "dsefs", "OpsCenter", "HiveMetaStore"}
    postdata = {"strategy_class": "NetworkTopologyStrategy", "strategy_options": datacenters, "durable_writes": True}
    rawjson = json.dumps(postdata)
    # loop over keyspaces
    print "Looping over keyspaces: {k}".format(k=', '.join(keyspaces))
    print "NOTE: No response indicates success"
    # keep track of non-sucess keyspaces to skip repairing
    skip = set()
    for ks in keyspaces:
        print "Calling: PUT {url}/{id}/keyspaces/{ks} with {d}".format(url=opsc.url, id=cid, ks=ks, d=rawjson)
        response = opsc.session.put("{url}/{id}/keyspaces/{ks}".format(url=opsc.url, id=cid, ks=ks), data=rawjson).json()
        print "Response: {r}".format(r=response)
        if response != None:
            # add to keyspaces to skip
            skip.add(ks)
            print "Non-success for keyspace: {ks}, excluding later...".format(ks=ks)
            lcm.pretty(response)

    print "Skipping keyspaces: {s}".format(s=', '.join(skip))
    for ks in skip:
        keyspaces.discard(ks)
    # look for version on all nodes, in case agent is down on some
    # dummy version for edge case where all agents aren't reporting, then bail
    version = '0'
    for n in nodes:
        if 'dse' in n['node_version']:
            version = n['node_version']['dse']
    if version.startswith('0'):
        print "Error: no DSE version found, exiting."
        # exiting with 0 as to not propigate error up to deploy
        exit(0)
    if version.startswith('5'):
        if args.norepair:
            print "--norepair passed, skipping repair and exiting."
            exit(0)
        print "DSE version: {v}, calling repairs".format(v=version)
        print "Running repairs"
        runRepair(opsc, cid, nodes, keyspaces)
    else:
        print "DSE version: {v}".format(v=version)
        if args.nodesync:
            # Explicitly add dse_system/solr_admin which aren't passed in because they're
            # EverywhereStrategy and therefore un-altered
            keyspaces.add("dse_system")
            keyspaces.add("solr_admin")
            # Explicitly skip system_auth and opsc KS's
            keyspaces.discard("OpsCenter")
            keyspaces.discard("system_auth")
            enableNodesync(opsc, cid, keyspaces)
            # Explicitly repair keyspaces system_auth and OpsCenter
            if args.norepair:
                print "--norepair passed, skipping repair and exiting."
                exit(0)
            runRepair(opsc, cid, nodes, {"system_auth", "OpsCenter"})
        else:
            if args.norepair:
                print "--norepair passed, skipping repair and exiting."
                exit(0)
            runRepair(opsc, cid, nodes, keyspaces)

# ----------------------------
if __name__ == "__main__":
    main()
