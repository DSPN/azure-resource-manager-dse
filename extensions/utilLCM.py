import json
import time
import requests
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry
from requests.packages.urllib3.exceptions import InsecureRequestWarning

def pretty(data):
    print '\n', json.dumps(data, sort_keys=True, indent=4), '\n'

class OpsCenter:
    """Class to contain OpsC ip/url/session state plus REST API methods"""
    def __init__(self, ip, user, password):
        self.ip = ip
        self.url = "http://" + ip + ":8888"
        self.user = user
        self.password = password
        self.session = requests.Session()
        # Explicitly ignoring self-signed SSL certs, this prints warnings
        self.session.verify = False
        # supress warnings
        requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
        # These scripts don't create new sessions, therefore we're setting the
        # retry logic here. The adapter mounting means any http(s) calls will
        # retry with an exponential backoff
        retries = 10,
        backoff_factor = 0.1,
        status_forcelist = (500, 502, 504)
        retry = Retry(
            total=retries,
            read=retries,
            connect=retries,
            backoff_factor=backoff_factor,
            status_forcelist=status_forcelist,
        )
        adapter = HTTPAdapter(max_retries=retry)
        self.session.mount('http://', adapter)
        self.session.mount('https://', adapter)

    def setupSession(self, pause, trys):
        # Constants that should go elsewhere?
        tout = 25
        # maxtrys * pause = 600 sec or 10 min, should be enough time for
        # OpsC instance to come up.
        count = 0
        while True:
            count += 1
            if count > trys:
                print "Error: OpsC connection failed after {n} trys".format(n=trys)
                return
            try:
                print "Trying: {url}/meta".format(url=self.url)
                meta = self.session.get("{url}/meta".format(url=self.url), timeout=tout)
            except requests.exceptions.Timeout as e:
                print "Request {c} to OpsC timeout, wait {p} sec...".format(c=count, p=pause)
                time.sleep(pause)
                continue
            except requests.exceptions.ConnectionError as e:
                print "Request {c} to OpsC refused, wait {p} sec...".format(c=count, p=pause)
                time.sleep(pause)
                continue
            except Exception as e:
                print "Request {c} to OpsC failed, wait {p} sec...".format(c=count, p=pause)
                time.sleep(pause)
                continue
            if (len(meta.history) > 0) and meta.history[0].status_code == 302:
                self.url = "https://" + self.ip + ":8443"
                print "Rerdirect detected, changing base url to: {url}".format(url=self.url)
            if meta.status_code == 200:
                data = meta.json()
                print "Found OpsCenter version: {version}".format(version=data['version'])
                return
            if meta.status_code == 401:
                print "Found OpsCenter with auth enabled, attempting login..."
                resp = self.attemptLogin(6)
                if resp == None:
                    print "All login attempts failed, exiting..."
                    exit(1)

    def attemptLogin(self, trys):
        count = 0
        while count < trys:
            resp = self.session.post("{url}/login".format(url=self.url), data={"username":self.user, "password":self.password}, timeout=25)
            if resp.status_code == 200:
                self.session.headers.update(resp.json())
                return resp
            else:
                print "Login attempt {c} failed, response: {j}".format(c=count, j=resp.json())
                print "Sleeping 10s before retry..."
                time.sleep(10)
            count += 1
        print "Error: OpsC connection failed after {n} trys".format(n=trys)
        return None

    def addCluster(self, cname, credid, repoid, configid, password):
        try:
            conf = json.dumps({
                'name': cname,
                'machine-credential-id': credid,
                'repository-id': repoid,
                'config-profile-id': configid,
                'old-password': 'cassandra',
                'new-password': password})
            clusterconf = self.session.post("{url}/api/v2/lcm/clusters/".format(url=self.url), data=conf).json()
            print "Added cluster, json:"
            pretty(clusterconf)
            return clusterconf['id']
        except requests.exceptions.Timeout as e:
            print "Request for cluster config timed out."
            return None
        except requests.exceptions.ConnectionError as e:
            print "Request for cluster config refused."
            return None
        except Exception as e:
            # Do something?
            raise
        return clusterconf

    def addCred(self, cred):
        try:
            creds = self.session.get("{url}/api/v2/lcm/machine_credentials/".format(url=self.url)).json()
            if creds['count'] == 0:
                creds = self.session.post("{url}/api/v2/lcm/machine_credentials/".format(url=self.url), data=cred).json()
                print "Added default dse creds, json:"
                pretty(creds)
                return creds
        except requests.exceptions.Timeout as e:
            print "Request to add ssh creds timed out."
            return None
        except requests.exceptions.ConnectionError as e:
            print "Request to add ssh creds refused."
            return None
        except Exception as e:
            # Do something?
            raise

    def addConfig(self, conf):
        try:
            configs = self.session.get("{url}/api/v2/lcm/config_profiles/".format(url=self.url)).json()
            if configs['count'] == 0:
                config = self.session.post("{url}/api/v2/lcm/config_profiles/".format(url=self.url), data=conf).json()
                print "Added default config profile, json:"
                pretty(config)
                return config
        except requests.exceptions.Timeout as e:
            print "Request to add config profile timed out."
            return None
        except requests.exceptions.ConnectionError as e:
            print "Request to add config profile refused."
            return None
        except Exception as e:
            # Do something?
            raise

    def addRepo(self, repo):
        try:
            repos = self.session.get("{url}/api/v2/lcm/repositories/".format(url=self.url)).json()
            if repos['count'] == 0:
                repconf = self.session.post("{url}/api/v2/lcm/repositories/".format(url=self.url), data=repo).json()
                print "Added default repo, json:"
                pretty(repconf)
                return repconf
        except requests.exceptions.Timeout as e:
            print "Request to add repo timed out."
            return None
        except requests.exceptions.ConnectionError as e:
            print "Request to add repo refused."
            return None
        except Exception as e:
            # Do something?
            raise

    def waitForCluster(self, cname, pause, trys):
        count = 0
        while True:
            count += 1
            if count > trys:
                return False
            found = self.checkForCluster(cname)
            if found:
                print "Cluster found."
                return True
            print "Cluster not found on try {c}, wait {p} sec...".format(c=count, p=pause)
            time.sleep(pause)

    def waitForNodes(self, numnodes, pause, trys):
        count = 0
        while True:
            count += 1
            if count > trys:
                return False
            nodes = self.session.get("{url}/api/v2/lcm/nodes/".format(url=self.url)).json()
            ncount = nodes["count"]
            if ncount >= numnodes:
                print "{n} nodes found.".format(n=numnodes)
                return True
            print "Only found {f} < {n} on try {c}, wait {p} sec...".format(f=ncount, n=numnodes, c=count, p=pause)
            time.sleep(pause)

    def checkForCluster(self, cname):
        try:
            clusters = self.session.get("{url}/api/v2/lcm/clusters/".format(url=self.url)).json()
            if not ('results' in clusters):
                return False
            for r in clusters['results']:
                if r['name'] == cname:
                    return True
            return False
        except requests.exceptions.Timeout as e:
            print "Request for cluster config timed out."
            return False
        except requests.exceptions.ConnectionError as e:
            print "Request for cluster config refused."
            return False
        except Exception as e:
            # Do something?
            raise

    def checkForDC(self, dcname):
        try:
            dcs = self.session.get("{url}/api/v2/lcm/datacenters/".format(url=self.url)).json()
            exists = False
            for dc in dcs['results']:
                if dc['name'] == dcname:
                    exists = True
            return exists
        except requests.exceptions.Timeout as e:
            print "Request to add repo timed out."
            return None
        except requests.exceptions.ConnectionError as e:
            print "Request to add repo refused."
            return None
        except Exception as e:
            # Do something?
            raise

    def addDC(self, dcname, cid):
        try:
            dc = json.dumps({
                'name': dcname,
                'cluster-id': cid,
                "graph-enabled": True,
                "solr-enabled": True,
                "spark-enabled": True})
            dcconf = self.session.post("{url}/api/v2/lcm/datacenters/".format(url=self.url), data=dc).json()
            # edge case where api returns "server error" string not json
            if isinstance(dcconf, (str, unicode)):
                print "Unexpected return value: ", dcconf
                print "Retry after 5s sleep..."
                time.sleep(5)
                dcconf = self.session.post("{url}/api/v2/lcm/datacenters/".format(url=self.url), data=dc).json()
            if 'code' in dcconf and (dcconf['code'] == 409):
                print "Warning: {d}".format(d=dcconf)
                print "Finding id for dcname='{n}'".format(n=dcname)
                alldcs = self.session.get("{url}/api/v2/lcm/datacenters/".format(url=self.url)).json()
                for r in alldcs['results']:
                    if r['name'] == dcname:
                        print "Found id='{n}'".format(n=r['id'])
                        return r['id']
            print "Added datacenter {n}, json:".format(n=dcname)
            pretty(dcconf)
            return dcconf['id']
        except requests.exceptions.Timeout as e:
            print "Request to add repo timed out."
            return None
        except requests.exceptions.ConnectionError as e:
            print "Request to add repo refused."
            return None
        except Exception as e:
            # Do something?
            raise

    # Install will use larger scope, if both passed.
    def triggerInstall(self, cid, dcid):
        scope = "datacenter"
        r_id = dcid
        if cid != None:
            scope = "cluster"
            r_id = cid
        job = {"job-type":"install",
               "job-scope":scope,
               "resource-id":r_id,
               "auto-bootstrap":False,
               "continue-on-error":True}
        data = json.dumps(job)
        response = self.session.post("{url}/api/v2/lcm/actions/install".format(url=self.url), data=data).json()
        pretty(response)
