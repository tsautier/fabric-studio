# Application Protection with FortiADC and FortiWeb

This Fabric Studio setup should reflect a production close environment basing on FortiGate Firewall, FortiWeb and FortiADC and application servers and as well as a kubernetes cluster. The purpose of this demo is to showcase multiple real world scenarios for protecting applications. 
![demo](images/demo.jpg)

This demo showcases the following actions:
- Configuring the Security Fabric Kubernetes SDN Connector
- Create an address object for the toolbox application running in the toolbox kubernetes namesace
- Verify the settings of the pre configured Explicit Proxy
- Create a Firewall Proxy rule for the toolbox application 
- Test egress traffic over the proxy from inide the toolsbox docker container

## Fabric-Studio - Demo Preparation Guide
The following guide explains how the setup a VNC connection from you local machine to the fabric-studio clinet (debcli) and admin (debadm). By using VNC allows to have a better keyboard mapping and screen resolution and overal increased performance. See [Fabric Studio Setup Guide](fabric-studio-demo-setup-guide.md)

## Demo Setup and Configuration
### Condigure FortiGate Explicit Web Proxy
Explicit web proxy can be configured on FortiGate for proxying HTTP and HTTPS traffic. Within this demo, we want do showcase that dockerized application running in kubernetes can be directed to pass egress traffic over a proxy (FortiGate) where the source application can be identified and denied or allowrd with the help of the Kubernetes SDN Connector. See [FortiGate Explicit Web Proxy](https://docs.fortinet.com/document/fortigate/7.6.2/administration-guide/300428/explicit-web-proxy)

### Diabling Kubernetes SourceNAT (SNAT) 
Most Kubernetes clusters are configured with Source NAT (SNAT) for outbound container traffic. As a result, all egress connections appear with the source IP address of the node hosting the originating pod. This prevents network administrators from creating firewall rules based on individual applications or pods.  Similarly, while the Kubernetes SDN Connector can resolve Kubernetes objects such as Namespaces and Pods, it cannot associate them with the actual IP addresses seen in network traffic due to SNAT.

![R01S09](images/R01S09.jpg)


### Review the Kubernetes SDN Connector
FortiOS automatically updates dynamic and cluster IP addresses for Kubernetes (K8s) by using a K8s SDN connector, enabling FortiOS to manage K8s pods as global address objects, as with other connectors. This includes mapping the following attributes from K8s instances to dynamic address groups in FortiOS.  See [Kubernetes (K8s) SDN connectors](https://docs.fortinet.com/document/fortigate/7.6.0/administration-guide/726316/kubernetes-k8s-sdn-connectors)

To access the FortiGate Web Interface, navigate in Fabric Studio to the FortiGate appliance and select Access -> HTTPS. Login as user 'admin' and the Fabric Demo Passwotd.
![fgtsdn0](images/fgtsdn0.jpg)
Navigate to the 'Security Fabric' on the Menubar at the left and chose the submenu 'External Connectors'. As you can see is the Kubernetes SDN already preconfigured but the statis is down. This is because the connection to the K3s Kubernetes Cluster is not yet established as the connecor requires the kubernetes security token. 
![fgtsdn1](images/fgtsdn1.jpg)
The security token can optained be either open terminal window in the debcli desktop or connect to the )debcli) instance in Fabric Studio with SSH. Enter the following command to retrief the security token. The output shown here is only an example and will not work for the SDN connector.

```
fortinet@debcli:~$ kubectl get secret toolbox-sa-token -n toolbox -o jsonpath='{.data.token}' | base64 -d && echo
eyJhbGciOiJSUzI1NiIsImtpZCI6Imw3UV80dkIxMXUzN1hjQ05JbEF4bmdOOXgzREEyd2ZVSWp0M0RSdjh6bzgifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJ0b29sYm94Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6InRvb2xib3gtc2EtdG9rZW4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoidG9vbGJveC1zYSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImExYTdkYTMzLTAyZTktNDE4OC05ZmIyLTQyNjMyOTIxOWU5OCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDp0b29sYm94OnRvb2xib3gtc2EifQ.JOVVPwjSsawUeHH7FkgqGJvcn-acsiqudeNOzKe25Mg0HPFEhAK3801Zex_X1-M7UW_7eYnATpT_QD0iFo9Kr3ZA7qsThfEJZtoR-GNgGvONr5FZGKu-GuzDZiASj2hLWSn6ejSvkJEB6_g0w2D3CMZlo4qVplarirjNhBmv4Op1XWyACuM2D92axU9y2zYsxhLiwguTw6wewj_CZSMFLuzDdLtsHLDj8WBezGKbX_TSU4JRtCKA3q5dUJOIqI60LmjBql94LEjpkP-4MvH8m4NAsRQv7sTuQoXpepZXbK77kbxJc2kYc0evhRbNhLyRAdRKI_KRG0Mfb2wiJ93rrA
```

![fgtsdn2](images/fgtsdn2.jpg)

Enter the token into the 'Securoty Token' field in the FortiGate administration interface and press 'ok'. Click top right of the 'k3s' box to refresh and the status icon should turn to 'up' shortly. Leaf the mouse on the 'k3s' box (without clicking to it) and the and a new box with 'View Connecor Objects' botton appears (see picture below). 

![fgtsdn3](images/fgtsdn3.jpg)

Press it and a new window appears showing all Kubernetes Objects found and the Service Account defined is giving you access to.

![fgtsdn4](images/fgtsdn4.jpg)

### Diabling Kubernetes SourceNAT (SNAT)
Most Kubernetes clusters are configured with Source NAT (SNAT) for outbound container traffic. As a result, all egress connections appear with the source IP address of the node hosting the originating pod. This prevents network administrators from creating firewall rules based on individual applications or pods.  Similarly, while the Kubernetes SDN Connector can resolve Kubernetes objects such as Namespaces and Pods, it cannot associate them with the actual IP addresses seen in network traffic due to SNAT.

## Setup Fortigate with Explicit Web Proxy and the Kubernetes SDN Connector
### Configure the Kubernetes SDN Connector


1. step 1

2.  Since the web server hosts three different domains on a single IP address, the challenge lies in handling HTTPS traffic correctly. When a client initiates a secure connection, such as accessing **https://www.globex.com**, the server must present the correct SSL/TLS certificate that matches the requested domain.

3. However, because HTTPS traffic is encrypted, the server cannot determine which domain the client is requesting until it begins decrypting the connection — which requires the correct certificate to start with. If the server presents the wrong certificate, the SSL/TLS handshake will fail. This creates a classic "chicken-and-egg" problem.

## Server Name Indication (SNI)

This is where **Server Name Indication (SNI)** solves the problem. SNI is an extension to the SSL/TLS protocol that allows the client to indicate the hostname it is trying to reach during the initial handshake.

All modern web browsers (except Internet Explorer on some older platforms) support SNI and send the requested domain name as part of the **Client Hello** message in plaintext. Because this part of the transmission is not encrypted, the web server — or any firewall performing SSL inspection — can read the requested domain name and select the appropriate SSL/TLS certificate *before* the encrypted session begins.

This ensures that the client receives the correct certificate, allowing the handshake to complete successfully and securing the connection to the right website.

# Demo Setup and Introduction

![layout](https://raw.githubusercontent.com/pivotal-sadubois/fabric-studio/main/demos/fortinet-sni-based-cert-selection/images/layout.png)





