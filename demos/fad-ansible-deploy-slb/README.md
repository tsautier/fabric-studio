# FortiADC - Deploy a Server Load Balancer (SLB) with Ansible
This scenario showcases the automated deployment of a L4 Server Load Balancer (SLB) on the Fortinet Application Delivery Controller (FortiADC) for the EmployeeDB Test Application running on three Backend Servers. The FortiADC Configuration is deployed wit am Ansible Playbook and suited for DevOps Teams required to maintain one ore more applications and do not have dep knowledge in the operation of a FortiADC. 

This demo showcases the following actions: 
- Create a Virtual IP Address for the EmployeeDB Applicaiton (employeedb-vip)
- Create a Real Server Pool (employeedb-pool)
- Create three Real Servers (employeedb-server-1, employeedb-server-2, employeedb-server-3)
- Create a Healthcheck 

![R13S06](https://raw.githubusercontent.com/pivotal-sadubois/fabric-studio/main/demos/fad-ansible-deploy-slb/images/R04S05.jpg)

# Forti Studio - Setup Guide
The following guide explains how the setup a VNC connection from you local machine to the fabric-studio clinet (debcli) and admin (debadm). By using 
VNC allows to have a better keyboard mapping and screen resolution and overal increased performance.
![SETUP.md](https://raw.githubusercontent.com/pivotal-sadubois/fabric-studio/main/demos/fad-ansible-deploy-slb/SETUP.md)



