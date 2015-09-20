import sys
print  sys.argv[1:]

# This python script generates an ARM template that deploys DSE across regions.  Arguments are passed in as a json file.
#
# First off we create the infrastructure that the OpsCenter node requires:
# (1) Vnet and a subnet within that to deploy to.
# (2) Public IP Address for OpsCenter
# (3) VM
# (4) Storage Account
#
# Then we loop through for each data center and create:
# (1) Vnet and a subnet within that to deploy to.
# (2) nodesPerRegion number of VMs
# (3) math.ceil(nodesPerRegion/40.0) number of storage accounts

# Then we loop across the Vnets (OpsCenter and the DSE nodes) and connect those all togther.  This requires creating:
# (1) Gateways in each Vnet
# (2) ...


