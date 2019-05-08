#!/usr/bin/python
import json
import argparse
import os
import utilLCM as lcm

def setupArgs():
    parser = argparse.ArgumentParser(description='Setup LCM managed DSE cluster, repo, config, and ssh creds',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    required = parser.add_argument_group('Required named arguments')
    required.add_argument('--clustername', required=True, type=str,
                          help='Name of cluster.')
    required.add_argument('--username', required=True, type=str,
                          help='username LCM uses when ssh-ing to nodes for install/config')
    required.add_argument('--repouser', required=True, type=str, help='username for DSE repo')
    required.add_argument('--repopw', required=True, type=str, help='pw for repouser')
    required.add_argument('--dbpasswd', required=True, type=str, help='pw for user cassandra')
    parser.add_argument('--opsc-ip', type=str, default='127.0.0.1',
                        help='IP of OpsCenter instance (or FQDN)')
    parser.add_argument('--opscuser', type=str, default='admin', help='opscenter admin user')
    parser.add_argument('--opscpw', type=str, default='admin', help='password for opscuser')
    parser.add_argument('--privkey', type=str,
                        help='abs path to private key (public key on all nodes) to be used by OpsCenter; --password OR --privkey required')
    parser.add_argument('--password', type=str,
                        help='password for username LCM uses when ssh-ing to nodes for install/config; --password OR --privkey required; IGNORED if privkey non-null.')
    parser.add_argument('--becomepw', action='store_true',
                        help='use arg --password when sudo prompts for pw on nodes. IGNORED if privkey non-null.')
    parser.add_argument('--dsever', type=str, default="6.0.0",
                        help='DSE version for LCM config profile')
    parser.add_argument('--datapath', type=str, default=None,
                        help='path to root data directory containing data | commitlog | saved_caches (eg /data/cassandra); package default if not passed')
    parser.add_argument('--nojava', action='store_true', help='disable java/jce policy install in default LCM config profile')
    parser.add_argument('--aoss', action='store_true', help='enable AOSS in default LCM config profile')
    parser.add_argument('--config', type=str, help='JSON for config profile. WILL OVERRIDE ALL OTHER CONFIG ARGUMENTS')
    parser.add_argument('--pause', type=int, default=6,
                        help="pause time (sec) between attempts to contact OpsCenter")
    parser.add_argument('--trys', type=int, default=100,
                        help="number of times to attempt to contact OpsCenter")
    parser.add_argument('--verbose', action='store_true', help='verbose flag')
    return parser

def checkArgs(args):
    if args.password is None and args.privkey is None:
        print "setupCluster.py: error: argument --password OR --privkey is required"
        print "Run setupCluster.py -h for help message"
        exit(1)
    #Todo add key exists check

def main():
    parser = setupArgs()
    args = parser.parse_args()
    checkArgs(args)

    # Basic repo config
    dserepo = {
        "name":"DSE repo",
        "username":args.repouser,
        "password":args.repopw}
    if args.verbose:
        print "Default repo config:"
        tmp = dserepo.copy()
        tmp['password'] = "XXXXX"
        lcm.pretty(tmp)

    # If privkey passed read key content...
    if args.privkey != None:
        keypath = os.path.abspath(args.privkey)
        with open(keypath, 'r') as keyfile:
            privkey = keyfile.read()
        print "Will create cluster {c} on {u} with keypath {k}".format(c=args.clustername, u=args.opsc_ip, k=keypath)
        dsecred = {
            "become-mode":"sudo",
            "use-ssh-keys":True,
            "name":"DSE creds",
            "login-user":args.username,
            "ssh-private-key":privkey,
            "become-user":None}
    # ...otherwise use a pw
    else:
        print "Will create cluster {c} on {u} with password".format(c=args.clustername, u=args.opsc_ip)
        dsecred = {
            "become-mode":"sudo",
            "use-ssh-keys":False,
            "name":"DSE creds",
            "login-user":args.username,
            "login-password":args.password,
            "become-user":None}
        if args.becomepw:
            dsecred['become-password'] = args.password
    if args.verbose:
        print "Default creds:"
        tmp = dsecred.copy()
        if 'login-password' in tmp: tmp['login-password'] = "XXXXX"
        if 'become-password' in tmp: tmp['become-password'] = "XXXXX"
        if 'ssh-private-key' in tmp: tmp['ssh-private-key'] = "ZZZZZ"
        lcm.pretty(tmp)
    # Minimal config profile
    defaultconfig = {
        "name":"Default config",
        "datastax-version": args.dsever,
        "json": {
            'cassandra-yaml': {
                "authenticator":"com.datastax.bdp.cassandra.auth.DseAuthenticator",
                "num_tokens":8,
                "allocate_tokens_for_local_replication_factor": 2,
                "endpoint_snitch":"org.apache.cassandra.locator.GossipingPropertyFileSnitch",
                "compaction_throughput_mb_per_sec": 64
            },
            "dse-yaml": {
                "authorization_options": {"enabled": True},
                "authentication_options": {"enabled": True},
                "dsefs_options": {"enabled": True}
            }
        }}
    # Since this isn't necessarily being called on the nodes where 'datapath'
    # exists checking is pointless
    if args.datapath != None:
        print "--datapath {p} passed, setting root datapath in default config".format(p=args.datapath)
        defaultconfig["json"]["cassandra-yaml"]["data_file_directories"] = [os.path.join(args.datapath, "data")]
        defaultconfig["json"]["cassandra-yaml"]["saved_caches_directory"] = os.path.join(args.datapath, "saved_caches")
        defaultconfig["json"]["cassandra-yaml"]["commitlog_directory"] = os.path.join(args.datapath, "commitlog")
        defaultconfig["json"]["dse-yaml"]["dsefs_options"]["work_dir"] = os.path.join(args.datapath, "dsefs")
        defaultconfig["json"]["dse-yaml"]["dsefs_options"]["data_directories"] = [{"dir": os.path.join(args.datapath, "dsefs/data")}]
    # if --aoss option passed, enable AOSS
    if args.aoss and args.dsever.startswith('6'):
        print "--aoss passed, adding enable AOSS to default config"
        defaultconfig["json"]["dse-yaml"]["alwayson_sql_options"] = {"enabled": True}
        defaultconfig["json"]["dse-yaml"]["resource_manager_options"] = {"worker_options": {"workpools": [{"memory": "0.4", "cores": "0.4", "name": "alwayson_sql"}]}}
    elif args.aoss and args.dsever.startswith('5'):
        print "WARNING: --aoss passed and DSE version <6, ignoring --aoss"
    # if nojava option passed, disable java/jce
    if args.nojava:
        print "--nojava passed, adding disable java/jce-policy to default config"
        defaultconfig["json"]["java-setup"] = {}
        defaultconfig["json"]["java-setup"]["manage-java"] = True

    # Overriding all config profile logic above
    # Todo, read config json from a file or http endpoint
    if args.config != None:
      print "WARNING: --config passed, OVERRIDING ALL OTHER config arguments"
      print "WARNING: Failed install job possible, e.g. if config json data"
      print "WARNING: paths don't match existing disks/paths"
      defaultconfig = json.loads(args.config)

    if args.verbose:
        print "Default config profile:"
        lcm.pretty(defaultconfig)

    opsc = lcm.OpsCenter(args.opsc_ip, args.opscuser, args.opscpw)
    # Block waiting for OpsC to spin up, create session & login if needed
    opsc.setupSession(pause=args.pause, trys=args.trys)

    # Return config instead of bool?
    # This check is here to allow calling script from node instances if desired.
    # Ie script may be called multiple times.
    # Cluster doesn't esist -> must be 1st node -> do setup
    c = opsc.checkForCluster(args.clustername)
    if not c:
        print "Cluster {n} doesn't exist, creating...".format(n=args.clustername)
        cred = opsc.addCred(json.dumps(dsecred))
        repo = opsc.addRepo(json.dumps(dserepo))
        conf = opsc.addConfig(json.dumps(defaultconfig))
        cid = opsc.addCluster(args.clustername, cred['id'], repo['id'], conf['id'], args.dbpasswd)
    else:
        print "Cluster {n} exists, exiting...".format(n=args.clustername)



# ----------------------------
if __name__ == "__main__":
    main()
