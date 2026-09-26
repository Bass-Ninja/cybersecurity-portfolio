# Cybersecurity Lab Cheatsheet

Quick-reference notes collected while building, observing, testing, and hardening the SecureBank cybersecurity lab.

This document is intended as a practical personal reference for commands, concepts, security-testing workflows, and mental models encountered during the labs.

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
NAT interface: eth0
Lab interface: eth1
Lab IP: 192.168.56.10
```

## Ubuntu Target

```text
NAT interface: enp0s3
Lab interface: enp0s8
Lab IP: 192.168.56.20
Hostname: securebank-target
Lab hostname: securebank.lab
```

---

# 2. VirtualBox Network Model

## NAT Adapter

Provides Internet access.

```text
VM
 │
 ▼
VirtualBox NAT
 │
 ▼
Internet
```

## Internal Network

Provides isolated communication between lab VMs.

```text
Kali 192.168.56.10
        │
        ▼
securebank-lab
        │
        ▼
Ubuntu 192.168.56.20
```

No gateway is required on the internal interface.

---

# 3. Docker Networking Mental Model

```text
container listening
≠
host port published
```

A service may exist inside Docker without being remotely reachable.

---

# 4. Docker Port Publishing

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

Another machine cannot normally connect to the host LAN/lab address on that port.

---

# 6. All-Interface Docker Binding

```yaml
ports:
  - "8080:8080"
```

often appears as:

```text
0.0.0.0:8080
[::]:8080
```

This exposes the service on host interfaces unless another firewall blocks it.

---

# 7. Internal-Only Container Service

No `ports:` entry is needed for container-to-container traffic.

```text
web → api:8080

api → postgres:5432

api → keycloak:8080
```

Key rule:

> Publish a host port only when something outside the Docker network requires direct access.

---

# 8. SecureBank Exposure Model

```text
External client / Kali
          │
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

| Port | Service | Exposure |
| ---: | --- | --- |
| `3443` | SecureBank HTTPS | Remote |
| `3000` | Nginx HTTP | Loopback |
| `8443` | API HTTPS | Loopback |
| `8080` | API HTTP | Docker only |
| `8081` | Keycloak HTTP | Loopback |
| `5432` | PostgreSQL | Docker only |

---

# 9. Docker Commands

```bash
docker ps
docker compose ps
docker compose up -d
docker compose up -d --build
docker compose down
docker compose logs --tail=100
docker compose logs -f api
docker network ls
docker network inspect <network>
```

---

# 10. SecureBank Lab Compose

Local:

```bash
docker compose up -d --build
```

Lab:

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.lab.yml \
  up -d --build
```

---

# 11. Docker Exec

```bash
docker exec <container> <command>
```

Example:

```bash
docker exec securebank-web \
  wget -qO- http://securebank-api:8080/health/ready
```

---

# 12. Windows TCP Testing

```powershell
Get-NetTCPConnection -State Listen
```

```powershell
Test-NetConnection localhost -Port 15432
```

Important:

```text
TcpTestSucceeded
```

---

# 13. Linux Network Interfaces

```bash
ip addr
```

Specific:

```bash
ip addr show enp0s8
```

---

# 14. Routing

```bash
ip route
```

Mental model:

```text
default route → NAT

192.168.56.0/24 → lab interface
```

---

# 15. Persistent Kali IP

```bash
nmcli connection show
```

```bash
sudo nmcli connection modify eth1 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.10/24 \
  ipv4.gateway ""
```

---

# 16. Ubuntu Netplan

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

```bash
sudo netplan try
sudo netplan apply
```

---

# 17. Connectivity

```bash
ping -c 4 192.168.56.20
```

```bash
ping securebank.lab
```

---

# 18. Hosts File

```text
192.168.56.20 securebank.lab
```

---

# 19. SSH

Install:

```bash
sudo apt install -y openssh-server
```

Enable:

```bash
sudo systemctl enable --now ssh
```

Connect:

```bash
ssh nina@192.168.56.20
```

Short timeout:

```bash
ssh -o ConnectTimeout=5 nina@192.168.56.20
```

---

# 20. HTTP Testing

```bash
curl http://host/path
```

HTTPS:

```bash
curl https://host/path
```

Self-signed lab certificate:

```bash
curl -k https://securebank.lab:3443
```

Headers:

```bash
curl -k -I https://securebank.lab:3443
```

---

# 21. HTTP vs HTTPS

HTTP:

```text
TCP
 ↓
HTTP plaintext
```

HTTPS:

```text
TCP
 ↓
TLS
 ↓
HTTP
```

HTTPS protects application payloads.

Network metadata remains visible.

---

# 22. TCP Handshake

```text
SYN
 ↓
SYN/ACK
 ↓
ACK
```

---

# 23. Wireshark Filters

```text
tcp
http
tls
dns
icmp
tcp.port == 8080
ip.addr == 192.168.56.20
```

---

# 24. Follow TCP Stream

```text
Right-click packet
→ Follow
→ TCP Stream
```

---

# 25. Lab 01 Lesson

```text
authentication
≠
transport confidentiality
```

Bearer token over HTTP:

```text
visible
```

Bearer token over HTTPS:

```text
encrypted in transit
```

---

# 26. Nmap Default Scan

```bash
nmap 192.168.56.20
```

A default scan does not scan every TCP port.

---

# 27. Full TCP Scan

```bash
nmap -p- 192.168.56.20
```

Scans:

```text
1–65535
```

---

# 28. Version Detection

```bash
nmap -sV -p 22,3443 192.168.56.20
```

---

# 29. Default NSE Scripts

```bash
nmap -sC -sV -p 22,3443 192.168.56.20
```

---

# 30. TLS Nmap Scripts

```bash
nmap -p 3443 \
  --script ssl-cert,ssl-enum-ciphers \
  192.168.56.20
```

---

# 31. OpenSSL TLS Inspection

```bash
openssl s_client \
  -connect securebank.lab:3443 \
  -servername securebank.lab
```

Observed:

```text
TLSv1.3
TLS_AES_256_GCM_SHA384
```

---

# 32. Self-Signed Certificate

```text
Verify return code: 18
```

Expected in this controlled lab.

---

# 33. Nginx Version Disclosure

Before:

```text
Server: nginx/1.29.8
```

Hardening:

```nginx
server_tokens off;
```

After:

```text
Server: nginx
```

---

# 34. Lab 02 Lesson

```text
container listening
≠
remotely exposed
```

---

# 35. Lab 03 Lesson

```text
service running
≠
discovered by default scan
```

Enumeration should be progressive.

---

# 36. UFW Status

```bash
sudo ufw status verbose
sudo ufw status numbered
```

---

# 37. UFW Defaults

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

---

# 38. Allow SecureBank

```bash
sudo ufw allow in on enp0s8 to any port 3443 proto tcp
```

---

# 39. Block and Log SSH

```bash
sudo ufw deny in on enp0s8 log proto tcp to any port 22
```

---

# 40. Enable UFW

```bash
sudo ufw enable
```

Always keep console access available when modifying firewall rules over SSH.

---

# 41. Nmap Port States

```text
open
→ service reachable
```

```text
closed
→ host responds, no service listening
```

```text
filtered
→ firewall/filter prevents normal determination
```

---

# 42. Check Listening Ports

```bash
sudo ss -ltnp
```

Specific:

```bash
sudo ss -ltnp | grep :22
```

---

# 43. Service State

```bash
sudo systemctl status ssh --no-pager
```

Important:

```text
service running
≠
remotely reachable
```

---

# 44. Firewall Logs

```bash
sudo journalctl -kf
```

Search:

```bash
sudo journalctl -k | grep UFW
```

Useful fields:

```text
SRC
DST
SPT
DPT
PROTO
```

---

# 45. Lab 04 Lesson

```text
firewall filtering
≠
service shutdown
```

And:

```text
block + log
=
prevention + visibility
```

---

# 46. Burp Suite

Start:

```bash
burpsuite
```

Useful areas:

```text
Proxy
├── Intercept
└── HTTP history
```

---

# 47. Burp Integrated Browser

Use:

```text
Proxy
→ Open browser
```

This avoids manually configuring a separate browser proxy for basic labs.

---

# 48. Burp Intercept

When enabled:

```text
Browser
   │
   ▼
Burp
   │
   X request paused
```

Use:

```text
Forward
```

to send the intercepted request.

For normal reconnaissance, turn Intercept off after login and use HTTP history.

---

# 49. HTTP History

HTTP history records requests even when Intercept is off.

Use it to inspect:

```text
method
URL
status
request headers
request body
response headers
response body
```

---

# 50. API Recon Workflow

```text
Authenticate normally
        ↓
Browse application
        ↓
Observe /api/ traffic
        ↓
Record endpoints
        ↓
Record HTTP methods
        ↓
Record query parameters
        ↓
Inspect request bodies
        ↓
Inspect response objects
        ↓
Map object identifiers
        ↓
Identify trust boundaries
```

---

# 51. Bearer Authentication

Observed:

```http
Authorization: Bearer <JWT>
```

Bearer tokens are credentials.

Never commit live token values into documentation.

Use:

```http
Authorization: Bearer <redacted>
```

---

# 52. JWT Structure

JWT:

```text
header.payload.signature
```

Useful claims observed in SecureBank:

```text
iss
aud
sub
exp
iat
azp
realm roles
```

---

# 53. SecureBank JWT Trust Model

```text
JWT
 │
 ├── issuer
 ├── audience
 ├── expiry
 ├── signature
 ├── subject
 └── roles
```

The API must validate the token rather than merely decode it.

---

# 54. User Context Mental Model

SecureBank collection endpoints do not send a user ID.

Example:

```http
GET /api/accounts
```

Instead:

```text
Bearer JWT
    │
    ▼
sub
    │
    ▼
UserContext
    │
    ▼
user-scoped data
```

---

# 55. No User ID Does Not Mean No BOLA

Important:

```text
no userId in URL
≠
no object authorization risk
```

Object IDs can still appear in:

```text
request bodies
URL resource IDs
responses
related objects
```

---

# 56. API Object References Discovered

Accounts:

```text
account id
account number
```

Transfers:

```text
transfer id
sourceAccountId
destinationAccountId
```

Beneficiaries:

```text
beneficiary id
accountId
accountNumber
```

---

# 57. Transfer Endpoint

```http
POST /api/transfers
```

Body:

```json
{
  "sourceAccountId": "...",
  "destinationAccountNumber": "...",
  "amount": 5,
  "currency": "EUR"
}
```

Important boundary:

```text
JWT subject
+
sourceAccountId
↓
ownership check
```

---

# 58. BOLA Mental Model

BOLA:

```text
Broken Object Level Authorization
```

Basic pattern:

```text
authenticated user
      │
      ▼
object ID supplied
      │
      ▼
server fails ownership check
      │
      ▼
unauthorized object access
```

---

# 59. SecureBank Transfer BOLA Candidate

Legitimate:

```text
sourceAccountId = user's account
```

Future test:

```text
sourceAccountId = another user's account
```

Expected secure behavior:

```text
request rejected
```

---

# 60. Beneficiary Delete Endpoint

```http
DELETE /api/beneficiaries/{id}
```

Critical boundary:

```text
JWT subject
+
beneficiary ID
↓
ownership check
```

---

# 61. SecureBank Beneficiary BOLA Candidate

Legitimate:

```text
DELETE own beneficiary
```

Future test:

```text
DELETE another user's beneficiary
```

Expected:

```text
rejected
```

---

# 62. Transfer Idempotency

Observed header:

```http
Idempotency-Key: <UUID>
```

Purpose:

```text
same logical request
+
same idempotency key
↓
operation should not execute twice
```

Future lab:

```text
replay identical transfer
```

---

# 63. Query Parameters

Transfer history:

```text
page
pageSize
sortBy
sortDirection
```

Potential future validation tests:

```text
page=0
pageSize=very-large
sortBy=invalid
sortDirection=invalid
```

Do not confuse reconnaissance with exploitation.

Map first, test later.

---

# 64. API Object Graph

```text
User
 │
 ├── Account
 │     └── accountId
 │
 ├── Transfer
 │     ├── transferId
 │     ├── sourceAccountId
 │     └── destinationAccountId
 │
 └── Beneficiary
       ├── beneficiaryId
       └── accountId
```

---

# 65. Identity vs Object Authorization

Identity:

```text
Who are you?
```

comes from:

```text
JWT
```

Authorization:

```text
Can you operate on this object?
```

requires checking:

```text
JWT subject
+
resource identifier
```

Authentication alone is not enough.

---

# 66. Reconnaissance vs Testing

Reconnaissance:

```text
discover
observe
map
classify
```

Testing:

```text
modify
replay
tamper
cross boundaries
verify controls
```

Do not mix them unnecessarily.

---

# 67. API Recon Principle

Same mindset as Nmap.

Networking:

```text
do not assume ports
→ discover them
```

API testing:

```text
do not assume endpoints
→ observe them
```

---

# 68. Labs 01–05 Progression

```text
Lab 01
HTTP vs HTTPS
      ↓
What crosses the network?

Lab 02
Docker Exposure
      ↓
What is reachable?

Lab 03
Nmap Enumeration
      ↓
What can an attacker discover?

Lab 04
Firewall Segmentation
      ↓
What should the attacker reach?

Lab 05
API Reconnaissance
      ↓
What application surface exists behind HTTPS?
```

---

# 69. Core Security Engineering Workflow

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

---

# 70. Commands / Tools Worth Remembering

Networking:

```bash
ip addr
ip route
ping -c 4 <host>
```

Nmap:

```bash
nmap <host>
nmap -p- <host>
nmap -sV -p <ports> <host>
nmap -sC -sV -p <ports> <host>
```

HTTP:

```bash
curl -k https://host
curl -k -I https://host
```

TLS:

```bash
openssl s_client -connect host:port -servername hostname
```

Docker:

```bash
docker compose ps
docker compose logs --tail=100
docker network inspect <network>
```

Firewall:

```bash
sudo ufw status verbose
sudo journalctl -kf
```

Sockets:

```bash
sudo ss -ltnp
```

Burp:

```text
Proxy → Intercept
Proxy → HTTP history
Proxy → Open browser
```

---

# 71. Commands Are Not the Objective

The important question is not:

> Which command should I memorize?

It is:

> What security question am I trying to answer?

Examples:

```text
nmap -p-
```

answers:

> Are services listening outside Nmap's default port set?

```text
ss -ltnp
```

answers:

> Is the service still listening locally?

Burp HTTP history answers:

> What API surface does the browser actually use?

Security tools are evidence-gathering mechanisms rather than the purpose of the lab.