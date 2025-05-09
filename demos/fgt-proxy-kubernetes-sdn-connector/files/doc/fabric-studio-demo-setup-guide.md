# Forti Studio - Demo Setup Guide
The following guide explains how the setup a VNC connection from you local machine to the fabric-studio clinet (debcli) and admin (debadm). By using
VNC allows to have a better keyboard mapping and screen resolution and overal increased performance.
## Verify VNC Access Settings
Open the CLI in the Fabric Studio and verify the VNC Access parametes for the 'Client' and 'Admin' debian systems.
```
(fabric-studio) # model fabric vm access list 'FortiADC Deploy SLB with Ansible' 'Admin' --select type=VNC
37 Default VNC PUBLIC access to Admin

(fabric-studio) # model fabric vm access list 'FortiADC Deploy SLB with Ansible' 'Client' --select type=VNC
41 Default VNC PUBLIC access to Client
```
In the case the output of the command show 'VNC PRIVATE access' for either the 'Admin0 or the 'Client0 system, the execure the
following command to modify it to 'VNC PUBLIC access'
```
(fabric-studio) # model vm access update 37 '{"mode": "PUBLIC"}'
37 Default VNC PUBLIC access to Admin
```


```
(fabric-studio) # system security preferences get
console="vnc_public_allowed='yes' spice_public_allowed='yes' public_password='required'" password="minimum_length=8 common_check='yes' numeric_check='yes' similarity_check='yes' complexity_check='yes'" ssh_public_allowed='yes' http_public_allowed='no' https_public_allowed='no' custom_rules_allowed='yes' web_session_age=3600 cli_session_timeout=900
```



