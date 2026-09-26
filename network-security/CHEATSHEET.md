# Networking & Security Lab Cheatsheet

Quick-reference notes collected while building and testing the SecureBank cybersecurity lab.

This document is intended as a practical personal reference for commands, concepts, and mental models encountered during the labs.

---

# 1. Lab Architecture

```text
                         Internet
                            │
                     VirtualBox NAT
                      │           │
                      │           │
                   Kali        Ubuntu
                      │           │
                 eth1 │           │ enp0s8
          192.168.56.10           192.168.56.20
                      └─────┬─────┘
                            │
                     securebank-lab
                     192.168.56.0/24
                            │
                            ▼
                    SecureBank Docker
```

## Kali

```text
NAT interface:      eth0
Lab interface:      eth1
Lab IP:             192.168.56.10
```

## Ubuntu Target

```text
NAT interface:      enp0s3
Lab interface:      enp0s8
Lab IP:             192.168.56.20
Hostname:           securebank-target
Lab hostname:       securebank.lab
```

---

# 2. VirtualBox Network Model

Each VM has two network interfaces.

## Adapter 1 — NAT

Provides Internet access.

```text
Kali / Ubuntu
     │
     ▼
VirtualBox NAT
     │
     ▼
Internet
```

The default route should normally remain on this interface.

## Adapter 2 — Internal Network

Provides communication only inside the isolated lab.

```text
Kali
192.168.56.10
      │
      │ securebank-lab
      ▼
Ubuntu
192.168.56.20
```

No gateway is required on this interface.

---

# 3. Networking Mental Models

## Host vs Container Network

A Docker container can listen on a port without that port being available outside Docker.

```text
container listening
≠
host port published
```

Example:

```text
API container
:8080
```

can exist internally without:

```text
host:8080
```

being reachable.

---

# 4. Docker Port Publishing

Example:

```yaml
ports:
  - "8080:8080"
```

means:

```text
host:8080
    ↓
container:8080
```

The service becomes reachable through host network interfaces unless the host side is restricted.

---

# 5. Loopback-Only Docker Binding

```yaml
ports:
  - "127.0.0.1:8080:8080"
```

means:

```text
localhost:8080
      ↓
container:8080
```

but another machine cannot normally use:

```text
HOST-LAN-IP:8080
```

to reach it.

Mental model:

```text
127.0.0.1
=
this machine only
```

---

# 6. All-Interface Binding

```yaml
ports:
  - "8080:8080"
```

typically appears as:

```text
0.0.0.0:8080->8080/tcp
[::]:8080->8080/tcp
```

`0.0.0.0` means all IPv4 host interfaces.

`[::]` means IPv6 interfaces.

This usually makes the service remotely reachable unless another firewall blocks it.

---

# 7. No Published Docker Port

```yaml
api:
  # no ports
```

does not mean the application stopped listening.

Containers on the same Docker network can still communicate.

Example:

```text
securebank-web
      │
      ▼
http://api:8080
```

or:

```text
API
 │
 ▼
postgres:5432
```

Key principle:

> A container only needs a published host port when something outside its Docker network requires direct access.

---

# 8. SecureBank Exposure Model

```text
External client / Kali
          │
          │ HTTPS
          ▼
      Nginx :3443
          │
     Docker network
       ┌──┴───────┐
       ▼          ▼
      API      Keycloak
       │
       ▼
   PostgreSQL
```

Current intended Docker exposure:

| Port | Service | Exposure |
| ---: | --- | --- |
| `3443` | Nginx / SecureBank HTTPS | Remote |
| `3000` | Nginx HTTP | Host loopback |
| `8443` | Direct API HTTPS | Host loopback |
| `8080` | API HTTP | Docker only |
| `8081` | Direct Keycloak HTTP | Host loopback |
| `5432` | PostgreSQL | Docker only |

---

# 9. Docker Commands

## Show Running Containers

```bash
docker ps
```

Compose:

```bash
docker compose ps
```

---

## Start Stack

```bash
docker compose up -d
```

Build images first:

```bash
docker compose up -d --build
```

---

## Recreate One Service

```bash
docker compose up -d --force-recreate api
```

Build and recreate:

```bash
docker compose up -d --build --force-recreate web
```

---

## Stop Stack

```bash
docker compose down
```

Delete persistent volumes too:

```bash
docker compose down --volumes
```

Use `--volumes` carefully.

---

# 10. SecureBank Lab Compose

Local development:

```bash
docker compose up -d --build
```

Security lab:

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.lab.yml \
  up -d --build
```

The base configuration stays suitable for localhost development.

The lab override contains VM-specific settings such as:

```text
securebank.lab
```

and the lab-specific Keycloak realm.

---

# 11. Docker Logs

All services:

```bash
docker compose logs --tail=100
```

Specific service:

```bash
docker compose logs api --tail=100
```

Follow continuously:

```bash
docker compose logs -f api
```

---

# 12. Docker Networks

List networks:

```bash
docker network ls
```

Inspect:

```bash
docker network inspect <network-name>
```

Useful information includes:

```text
network subnet
container names
container IP addresses
connected services
```

---

# 13. Run Commands Inside Containers

General form:

```bash
docker exec <container> <command>
```

Example:

```bash
docker exec securebank-web \
  wget -qO- http://securebank-api:8080/health/ready
```

This is useful for proving container-to-container connectivity.

---

# 14. Windows Port Testing

Show TCP listeners:

```powershell
Get-NetTCPConnection -LocalPort 8080
```

Multiple ports:

```powershell
Get-NetTCPConnection -State Listen |
    Where-Object {
        $_.LocalPort -in 8080,8443,8081,15432,3443
    } |
    Format-Table LocalAddress,LocalPort,State,OwningProcess
```

---

# 15. Test TCP Reachability on Windows

```powershell
Test-NetConnection localhost -Port 15432
```

Important field:

```text
TcpTestSucceeded : True
```

or:

```text
TcpTestSucceeded : False
```

---

# 16. Linux Network Interfaces

Show interfaces:

```bash
ip addr
```

Specific interface:

```bash
ip addr show eth1
```

or:

```bash
ip addr show enp0s8
```

---

# 17. Linux Routing Table

```bash
ip route
```

Example Kali model:

```text
default via 10.0.2.2 dev eth0
192.168.56.0/24 dev eth1
```

Meaning:

```text
Internet traffic
→ eth0 / NAT

Lab traffic
→ eth1
```

The lab interface does not need a default gateway.

---

# 18. Temporary Static IP Address

Ubuntu example:

```bash
sudo ip addr add 192.168.56.20/24 dev enp0s8
```

Kali example:

```bash
sudo ip addr add 192.168.56.10/24 dev eth1
```

These changes normally disappear after reboot.

---

# 19. Persistent Kali Address with NetworkManager

Show connections:

```bash
nmcli connection show
```

Configure:

```bash
sudo nmcli connection modify eth1 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.10/24 \
  ipv4.gateway ""
```

Restart:

```bash
sudo nmcli connection down eth1
sudo nmcli connection up eth1
```

---

# 20. Persistent Ubuntu Address with Netplan

Example:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true

    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.56.20/24
```

Test safely:

```bash
sudo netplan try
```

Apply:

```bash
sudo netplan apply
```

Do not configure another default gateway on the isolated interface.

---

# 21. Basic Connectivity Testing

Kali → Ubuntu:

```bash
ping -c 4 192.168.56.20
```

Ubuntu → Kali:

```bash
ping -c 4 192.168.56.10
```

Hostname:

```bash
ping securebank.lab
```

---

# 22. Hostname Resolution

Kali `/etc/hosts` entry:

```text
192.168.56.20 securebank.lab
```

Add:

```bash
echo '192.168.56.20 securebank.lab' |
  sudo tee -a /etc/hosts
```

---

# 23. SSH Server

Install on Ubuntu:

```bash
sudo apt install -y openssh-server
```

Enable immediately and at boot:

```bash
sudo systemctl enable --now ssh
```

Check:

```bash
sudo systemctl status ssh --no-pager
```

---

# 24. SSH Client

Connect:

```bash
ssh nina@192.168.56.20
```

Short timeout:

```bash
ssh -o ConnectTimeout=5 nina@192.168.56.20
```

Exit:

```bash
exit
```

---

# 25. HTTP Testing with curl

HTTP:

```bash
curl http://host:port/path
```

HTTPS:

```bash
curl https://host/path
```

Ignore certificate trust errors in the controlled self-signed lab:

```bash
curl -k https://securebank.lab:3443
```

Headers only:

```bash
curl -k -I https://securebank.lab:3443
```

`-k` disables certificate verification.

Do not treat that as normal production behavior.

---

# 26. HTTP vs HTTPS Mental Model

## HTTP

```text
TCP
 ↓
HTTP
```

Application data is plaintext on the network.

A packet capture may expose:

```text
HTTP method
URL/path
headers
Authorization bearer token
request body
response body
```

---

## HTTPS

```text
TCP
 ↓
TLS
 ↓
HTTP
```

The HTTP contents are protected by TLS.

A passive network observer can still see metadata such as:

```text
source/destination IP
source/destination ports
packet lengths
timing
TLS handshake
certificate
TLS version
cipher suite
```

but normal HTTP content is encrypted.

---

# 27. TCP Three-Way Handshake

```text
Client → Server   SYN
Server → Client   SYN/ACK
Client → Server   ACK
```

Then application data can flow.

---

# 28. TCP Sequence and Acknowledgement Numbers

Mental model:

```text
Sequence number
=
position of my outgoing data
```

```text
Acknowledgement number
=
next byte I expect from you
```

SYN consumes one sequence number.

---

# 29. Wireshark Filters

TCP:

```text
tcp
```

HTTP:

```text
http
```

TLS:

```text
tls
```

DNS:

```text
dns
```

ICMP:

```text
icmp
```

Specific TCP port:

```text
tcp.port == 8080
```

Specific IP:

```text
ip.addr == 192.168.56.20
```

---

# 30. Follow a TCP Stream

In Wireshark:

```text
Right-click packet
→ Follow
→ TCP Stream
```

Useful for reconstructing plaintext TCP conversations such as HTTP.

---

# 31. Lab 01 Core Lesson

Plaintext HTTP can expose authentication material.

```text
Bearer token over HTTP
→ visible in packet capture
```

With TLS:

```text
Bearer token over HTTPS
→ encrypted in transit
```

Important:

> Authentication does not automatically provide transport confidentiality.

---

# 32. Nmap Default Scan

```bash
nmap 192.168.56.20
```

The default scan checks commonly used TCP ports.

It does not guarantee that every listening TCP service will be discovered.

In the lab, the default scan found:

```text
22/tcp open ssh
```

but initially missed SecureBank on:

```text
3443/tcp
```

---

# 33. Full TCP Port Scan

```bash
nmap -p- 192.168.56.20
```

`-p-` means:

```text
scan TCP ports 1–65535
```

This discovered:

```text
22/tcp
3443/tcp
```

Important:

> Discovery should not rely only on ports you already know exist.

---

# 34. Service and Version Detection

```bash
nmap -sV -p 22,3443 192.168.56.20
```

Example result:

```text
22/tcp
OpenSSH 10.2p1

3443/tcp
ssl/http
nginx 1.29.8
```

---

# 35. Aggressive Version Detection

```bash
nmap -sV --version-all -p 3443 192.168.56.20
```

Useful when normal version detection does not provide enough information.

---

# 36. Nmap Default Scripts

```bash
nmap -sC -sV -p 22,3443 192.168.56.20
```

`-sC` runs Nmap's default NSE script set.

Useful information can include:

```text
HTTP title
server information
TLS certificate
certificate SANs
protocol metadata
```

---

# 37. TLS Certificate Enumeration with Nmap

```bash
nmap -p 3443 \
  --script ssl-cert \
  192.168.56.20
```

Useful fields:

```text
subject
issuer
SAN values
key type
key size
validity dates
signature algorithm
```

---

# 38. TLS Cipher Enumeration

```bash
nmap -p 3443 \
  --script ssl-enum-ciphers \
  192.168.56.20
```

Combined:

```bash
nmap -p 3443 \
  --script ssl-cert,ssl-enum-ciphers \
  192.168.56.20
```

The SecureBank lab supported:

```text
TLS 1.2
TLS 1.3
```

---

# 39. OpenSSL TLS Inspection

```bash
openssl s_client \
  -connect securebank.lab:3443 \
  -servername securebank.lab
```

Useful fields include:

```text
certificate subject
issuer
TLS version
cipher
key exchange group
certificate verification result
```

Observed lab negotiation:

```text
Protocol: TLSv1.3
Cipher: TLS_AES_256_GCM_SHA384
```

---

# 40. Self-Signed Certificate Error

Lab output:

```text
Verify return code: 18 (self-signed certificate)
```

This is expected because the lab certificate is locally generated and not signed by a trusted public CA.

It does not automatically mean TLS encryption failed.

---

# 41. Nginx Version Disclosure

Before hardening:

```text
Server: nginx/1.29.8
```

Nginx configuration:

```nginx
server_tokens off;
```

After:

```text
Server: nginx
```

Verify:

```bash
curl -k -I https://securebank.lab:3443
```

Security principle:

> Avoid exposing unnecessary implementation details.

---

# 42. SecureBank Security Headers

Observed application headers include:

```text
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: no-referrer
Permissions-Policy
Content-Security-Policy
```

TLS and security headers solve different problems.

```text
TLS
→ protects data in transit
```

```text
browser security headers
→ influence browser security behavior
```

---

# 43. Lab 02 Core Lesson

```text
container listening
≠
service exposed to host/network
```

Container-to-container communication does not require host port publishing.

Example:

```text
API → postgres:5432
```

works without:

```text
host:15432
```

being exposed.

---

# 44. Lab 03 Core Lesson

```text
service running
≠
service discovered by default scan
```

Reconnaissance is progressive.

Useful workflow:

```text
default scan
    ↓
full port scan
    ↓
service detection
    ↓
protocol-specific enumeration
```

---

# 45. Basic Enumeration Workflow

```text
Identify target
      ↓
Check reachability
      ↓
Default scan
      ↓
Full TCP scan
      ↓
Service detection
      ↓
Protocol-specific enumeration
      ↓
Analyze findings
      ↓
Remediate
      ↓
Rescan
```

---

# 46. UFW Status

```bash
sudo ufw status verbose
```

Show rule numbers:

```bash
sudo ufw status numbered
```

---

# 47. UFW Default Policies

Deny unsolicited incoming traffic:

```bash
sudo ufw default deny incoming
```

Allow outgoing:

```bash
sudo ufw default allow outgoing
```

Mental model:

```text
incoming
→ deny unless explicitly allowed

outgoing
→ allow
```

---

# 48. Enable / Disable UFW

Enable:

```bash
sudo ufw enable
```

Disable:

```bash
sudo ufw disable
```

Be careful when enabling firewall rules over SSH.

Have console access or another recovery method available first.

---

# 49. Interface-Specific UFW Allow Rule

Allow SecureBank only through the lab interface:

```bash
sudo ufw allow in on enp0s8 to any port 3443 proto tcp
```

Breakdown:

```text
allow
→ permit

in
→ incoming traffic

on enp0s8
→ only this interface

to any port 3443
→ destination TCP port 3443

proto tcp
→ TCP only
```

---

# 50. Interface-Specific UFW Deny Rule

```bash
sudo ufw deny in on enp0s8 to any port 22 proto tcp
```

Blocks SSH arriving through the isolated lab interface.

---

# 51. UFW Deny + Log

Working syntax used in the lab:

```bash
sudo ufw deny in on enp0s8 log proto tcp to any port 22
```

This:

```text
blocks
+
logs
```

matching connection attempts.

---

# 52. Delete UFW Rules

Show numbered rules:

```bash
sudo ufw status numbered
```

Delete by number:

```bash
sudo ufw delete 2
```

Run:

```bash
sudo ufw status numbered
```

again afterwards because rule numbers can shift.

---

# 53. Nmap Port States

## Open

```text
open
```

A service is reachable and accepting connections.

## Closed

```text
closed
```

The host responded, but nothing is listening.

## Filtered

```text
filtered
```

A firewall or packet filter prevents Nmap from determining normal service reachability.

Lab 04 example:

```text
Before:
22/tcp open

After UFW:
22/tcp filtered
```

---

# 54. Service State vs Network Reachability

Important distinction:

```text
service running
≠
service remotely reachable
```

Lab example:

```text
sshd:
active

TCP 22:
listening

Kali:
cannot connect
```

The firewall controls reachability without stopping the service.

---

# 55. Check Linux Listening TCP Ports

All:

```bash
ss -ltn
```

With process information:

```bash
sudo ss -ltnp
```

Specific port:

```bash
sudo ss -ltnp | grep :22
```

Observed:

```text
0.0.0.0:22
[::]:22
```

Meaning SSH listens on IPv4 and IPv6.

---

# 56. systemd Service State

SSH:

```bash
sudo systemctl status ssh --no-pager
```

Start:

```bash
sudo systemctl start ssh
```

Stop:

```bash
sudo systemctl stop ssh
```

Enable at boot:

```bash
sudo systemctl enable ssh
```

Enable and start:

```bash
sudo systemctl enable --now ssh
```

---

# 57. Firewall Logging

Kernel journal:

```bash
sudo journalctl -k
```

Watch live:

```bash
sudo journalctl -kf
```

Search UFW entries:

```bash
sudo journalctl -k | grep UFW
```

Search destination port 22:

```bash
sudo journalctl -k | grep 'DPT=22'
```

---

# 58. Firewall Log Fields

Common fields:

```text
SRC=
source IP

DST=
destination IP

SPT=
source port

DPT=
destination port

PROTO=
protocol
```

Lab example:

```text
SRC=192.168.56.10
DST=192.168.56.20
DPT=22
PROTO=TCP
```

Meaning:

```text
Kali
192.168.56.10
      ↓
attempted TCP connection
      ↓
Ubuntu
192.168.56.20:22
```

---

# 59. Public Plane vs Management Plane

Public application:

```text
SecureBank HTTPS
TCP/3443
```

Management:

```text
SSH
TCP/22
```

Security principle:

> Management services should not automatically be reachable from the same networks as public application services.

---

# 60. Host Firewall vs Full Network Segmentation

Current lab:

```text
Kali
192.168.56.10

Ubuntu
192.168.56.20
```

Both are inside:

```text
192.168.56.0/24
```

So they are still in the same Layer 3 subnet.

UFW provides:

```text
host firewall enforcement
+
service segmentation
```

Full network segmentation would more commonly involve:

```text
different VLANs
different subnets
routing boundaries
firewalls between zones
```

---

# 61. Lab 04 Core Lesson

```text
service listening
≠
attacker can reach service
```

And:

```text
firewall filtering
≠
service shutdown
```

A firewall can reduce the attack surface while keeping required local functionality intact.

---

# 62. Prevention + Visibility

A useful firewall rule can provide:

```text
prevention
+
telemetry
```

Example:

```text
SSH attempt
     ↓
UFW
     ↓
blocked
     ↓
logged
```

Later this could become:

```text
UFW log
   ↓
Wazuh
   ↓
detection rule
   ↓
alert
```

---

# 63. Firewall Verification Workflow

```text
Baseline scan
      ↓
Configure firewall
      ↓
Rescan
      ↓
Test allowed service
      ↓
Test blocked service
      ↓
Verify local service state
      ↓
Inspect firewall logs
```

The control is not considered verified merely because the configuration file looks correct.

Test the observable result.

---

# 64. Core Security Engineering Workflow

Used throughout the portfolio:

```text
Build / Configure
       ↓
Observe
       ↓
Test
       ↓
Analyze
       ↓
Remediate
       ↓
Verify
```

Examples:

```text
Lab 01
observe HTTP traffic
→ enable TLS
→ verify confidentiality
```

```text
Lab 02
observe Docker exposure
→ remove unnecessary publishing
→ verify application still works
```

```text
Lab 03
enumerate services
→ find version disclosure
→ harden Nginx
→ rescan
```

```text
Lab 04
enumerate reachable services
→ firewall management access
→ verify SecureBank remains reachable
→ verify blocked traffic
```

---

# 65. Labs 01–04 Progression

```text
Lab 01
HTTP vs HTTPS Traffic Analysis
        ↓
What information crosses the network?
        ↓
Lab 02
Docker Network Exposure
        ↓
What services are exposed?
        ↓
Lab 03
Nmap Service Enumeration
        ↓
What can an attacker discover?
        ↓
Lab 04
Host Firewall and Service Segmentation
        ↓
What should the attacker actually be allowed to reach?
```

---

# 66. Commands Worth Memorizing

Networking:

```bash
ip addr
ip route
ping -c 4 <host>
```

SSH:

```bash
ssh user@host
ssh -o ConnectTimeout=5 user@host
```

Docker:

```bash
docker compose ps
docker compose logs --tail=100
docker network ls
docker network inspect <network>
```

HTTP:

```bash
curl -k https://host
curl -k -I https://host
```

Nmap:

```bash
nmap <host>
nmap -p- <host>
nmap -sV -p <ports> <host>
nmap -sC -sV -p <ports> <host>
```

TLS:

```bash
openssl s_client -connect host:port -servername hostname
```

Firewall:

```bash
sudo ufw status verbose
sudo ufw status numbered
sudo journalctl -kf
```

Sockets:

```bash
sudo ss -ltnp
```

Services:

```bash
sudo systemctl status <service>
```

---

# 67. Commands Are Not the Goal

Do not memorize tools without understanding why they are being used.

Example:

```bash
nmap -p-
```

is useful because:

> A default scan might miss a service running on a non-standard port.

Example:

```bash
ss -ltnp
```

is useful because:

> It proves whether a service is still listening locally even when a remote scan shows the port as filtered.

Example:

```bash
journalctl -kf
```

is useful because:

> It lets you correlate a network test with the defensive telemetry produced by the system.

The important skill is choosing the next command based on the security question being investigated.