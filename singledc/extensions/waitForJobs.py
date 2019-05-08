#!/usr/bin/python
import argparse
import time
import requests
import utilLCM as lcm

def setupArgs():
    parser = argparse.ArgumentParser(description='Block template shell until LCM jobs are not in RUNNING/PENDING state.',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--num', type=int, default=1, help='Expected number of jobs')
    parser.add_argument('--opsc-ip', type=str, default='127.0.0.1',
                        help='IP of OpsCenter instance (or FQDN)')
    parser.add_argument('--opscuser', type=str, default='admin', help='opscenter admin user')
    parser.add_argument('--opscpw', type=str, default='admin', help='password for opscuser')
    parser.add_argument('--pause', type=int, default=60,
                        help="pause time (sec) between attempts to contact OpsCenter")
    parser.add_argument('--trys', type=int, default=100,
                        help="number of times to attempt to contact OpsCenter")

    return parser

def runningJob(jobs):
    running = False
    for r in jobs['results']:
        if r['status'] == 'RUNNING' or r['status'] == 'PENDING' or r['status'] == 'WILL_FAIL':
            return True

def main():
    parser = setupArgs()
    args = parser.parse_args()

    opsc = lcm.OpsCenter(args.opsc_ip, args.opscuser, args.opscpw)
    # Block waiting for OpsC to spin up, create session & login if needed
    opsc.setupSession(pause=args.pause, trys=args.trys)

    count = 0
    while True:
        count += 1
        if count > args.trys:
            print "Maximum attempts, exiting"
            exit()
        try:
            jobs = opsc.session.get("{url}/api/v2/lcm/jobs/".format(url=opsc.url)).json()
        except requests.exceptions.Timeout as e:
            print "Request {c} to OpsC timeout after initial connection, exiting.".format(c=count)
            exit()
        except requests.exceptions.ConnectionError as e:
            print "Request {c} to OpsC refused after initial connection, exiting.".format(c=count)
            exit()
        lcm.pretty(jobs)
        if jobs['count'] == 0:
            print "No jobs found on try {c}, sleeping {p} sec...".format(c=count, p=args.pause)
            time.sleep(args.pause)
            continue
        if runningJob(jobs):
            print "Jobs running/pending on try {c}, sleeping {p} sec...".format(c=count, p=args.pause)
            time.sleep(args.pause)
            continue
        if (not runningJob(jobs)) and (jobs['count'] < args.num):
            print "Jobs found on try {c} but num {j} < {n}, sleeping {p} sec...".format(c=count, j=jobs['count'], n=args.num, p=args.pause)
            time.sleep(args.pause)
            continue
        if (not runningJob(jobs)) and (jobs['count'] >= args.num):
            print "No jobs running/pending and num >= {n} on try {c}, exiting".format(n=args.num, c=count)
            break



# ----------------------------
if __name__ == "__main__":
    main()
