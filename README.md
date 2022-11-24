# skyline-endpoint-ops
## Prerequisites:

- Skyline CLI [Link](https://flings.vmware.com/skyline-cli)
- Powershell
- PowerCLI
- Skyline users and permissions 
- VM Name schema of endpoints based on FQDN
 - vCenter: vcsa.vmware.local
 - vROPs: vrops.vmware.local
 - NSX-T: nsx-01.vmware.local, nsx-02.vmware.local, nsx-03.vmware.local | VIP nsx.vmware.local
  
## Workflow 1 create endpoints:

- Login to vCenter
- find all management VMs
- execute SkylineCLI and create corresponding endpoints

## Workflow 2 monitor endpoints and update if required:

- SkylineCLI monitor
- Skyline CLI update endpoint if necessary

## Workflow 3 check if endpoints exist if not create:

- list all existing endpoints using SkylineCLI
- get all management VMs from VC
- compare and add what is not existing in Skyline collector

## SkylineCLI Commands:

#### List all endpoints:

Remark: if no Webhook is provided the action will provide a list of the endpoints including status

```
skylinecli --action=monitor_slack --username admin --password PASSWORD --collector COLLECTOR-IP --insecure=true --output=true
```
#### Add Endpoint

```
skylinecli --action=add --username admin --password PASSWORD --collector COLLECTOR-IP --insecure=true --eptype=VSPHERE --epuser="ENDPOINT-USER" --eppassword="ENDPOINT-PASSWORD" --ep="ENDPOINT-FQDN"
```
#### Update vSphere Endpoint

```
skylinecli --action=update --username admin --password PASSWORD --collector COLLECTOR-IP --insecure=true --eptype=VSPHERE --epuser="ENDPOINT-USER" --eppassword="ENDPOINT-PASSWORD" --ep="ENDPOINT-FQDN"
```
#### Update vROPs Endpoint

```
skylinecli --action=update --username admin --password PASSWORD --collector COLLECTOR-IP --insecure=true --eptype=VROPS --epuser="ENDPOINT-USER" --eppassword="ENDPOINT-PASSWORD" --ep="ENDPOINT-FQDN"
```

#### Update NSX-T Endpoint

```
skylinecli --action=update --username admin --password PASSWORD --collector COLLECTOR-IP --insecure=true --eptype=NSX_T --epuser="ENDPOINT-USER" --eppassword="ENDPOINT-PASSWORD" --ep="ENDPOINT-FQDN"
```

#### Update LCM Endpoint

```
skylinecli --action=update --username admin --password PASSWORD --collector COLLECTOR-IP --insecure=true --eptype=LCM --epuser="ENDPOINT-USER" --eppassword="ENDPOINT-PASSWORD" --ep="ENDPOINT-FQDN"
```

## Powershell script using PowerCLI and SkylineCLI

#### Download the script and the json file

```
git clone https://github.com/mdhemmi/skyline-endpoint-ops.git
```

#### Adjust the config json file based on your environment

| Parameter | Description | Example |
|---|---|---|
|SkylineCLI|Path to the SkylineCLI binary| /Users/mdhemmi/Documents/skyline-endpoint-ops/skylinecli-darwin-arm64-1.0.5 |
|vcsa|vCenter FQDN|vcsa.vmware.local|
|SkylineVCUser| vCenter username with Skyline permissions based on docs|skywatcher@vsphere.local|
|SkylineVCUserPass|Corresponding password|VMware123!|
|Collector|Skyline collector FQDN|skyline.vmware.local|
|CollectorUser|Skyline collector user|admin|
|CollectorUserPass|Corresponding password|VMware123!|
|vROPsUser|vROPs user for Skyline|skywatcher|
|vROPsUserPassword|Corresponding password|VMware123!|
|NSXTUser|NSX-T user (until 3.2 the admin user has to be used)|admin|
|NSXTPassword|Corresponding password|VMware123!|
|LCMUser|LCM user for Skyline|admin@local|
|LCMPassword|Corresponding password|VMware123!|
|vCenterFilter|Filter string to find vCenter|vc|
|vROPsFilter|Filter string to find|vrops|
|NSXTFilter|Filter string to find|nsx|
|LCMFilter|Filter string to find|lcm|

```
vi skyline_ops.json
```
```
{
    "SkylineCLI": "/PATH/TO/skylinecli-darwin-arm64-1.0.5",
    "vcsa":  "VCENTER-FQDN",
    "SkylineVCUser": "skywatcher@vsphere.local",
    "SkylineVCUserPass": "VMware123!",
    "Collector": "COLLECTOR-FQDN",
    "CollectorUser": "admin",
    "CollectorUserPass": "VMware123!",
    "vROPsUser": "skywatcher",
    "vROPsUserPassword": "VMware123!",
    "NSXTUser": "admin",
    "NSXTPassword": "VMware123!",
    "vCenterFilter": "vc",
    "vROPsFilter": "vrops",
    "NSXTFilter": "nsx",
    "LCMFilter": "lcm"
}
```
#### Run the powershell script
```
./skyline-endpoint-ops.ps1
```
#### Example Output if no Endpoints are existing
```
--------------------------------------------------------------------------------------------------------------
[11-24-2022_09-38-04] Connect to vCenter vcsa.oz.xmsoft.de
[11-24-2022_09-38-05] Get endpoints from vCenter vcsa.oz.xmsoft.de
[11-24-2022_09-38-05] Get endpoints from Skyline Collector 192.168.19.47
[11-24-2022_09-38-05] Compare Endpoints in Skyline Collector vs. found Endpoints
[11-24-2022_09-38-05] vcsa.oz.xmsoft.de not found in Skyline Collector 192.168.19.47
[11-24-2022_09-38-05] Add Endpoint vcsa.oz.xmsoft.de in Skyline Collector 192.168.19.47
[11-24-2022_09-38-10] Endpoint created
[11-24-2022_09-38-10] vrops.oz.xmsoft.de not found in Skyline Collector 192.168.19.47
[11-24-2022_09-38-10] Add Endpoint vrops.oz.xmsoft.de in Skyline Collector 192.168.19.47
[11-24-2022_09-38-14] Endpoint created
[11-24-2022_09-38-14] Disconnect from vcsa.oz.xmsoft.de
--------------------------------------------------------------------------------------------------------------
```

#### Example Output if all Endpoints are working as expected
```
--------------------------------------------------------------------------------------------------------------
[11-24-2022_09-36-19] Connect to vCenter vcsa.oz.xmsoft.de
[11-24-2022_09-36-20] Get endpoints from vCenter vcsa.oz.xmsoft.de
[11-24-2022_09-36-21] Get endpoints from Skyline Collector 192.168.19.47
[11-24-2022_09-36-21] Compare Endpoints in Skyline Collector vs. found Endpoints
[11-24-2022_09-36-21] Found vcsa.oz.xmsoft.de in Skyline Collector 192.168.19.47
[11-24-2022_09-36-21] Check status of vcsa.oz.xmsoft.de in Skyline Collector 192.168.19.47
[11-24-2022_09-36-21] Endpoint status of vcsa.oz.xmsoft.de is OK
[11-24-2022_09-36-21] Found vrops.oz.xmsoft.de in Skyline Collector 192.168.19.47
[11-24-2022_09-36-21] Check status of vrops.oz.xmsoft.de in Skyline Collector 192.168.19.47
[11-24-2022_09-36-21] Endpoint status of vrops.oz.xmsoft.de is OK
[11-24-2022_09-36-21] Disconnect from vcsa.oz.xmsoft.de
--------------------------------------------------------------------------------------------------------------
```

