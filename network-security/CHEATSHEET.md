# Cybersecurity Lab Cheatsheet

Quick-reference notes for the SecureBank cybersecurity lab.

Use this file for:

- commands
- observed configuration
- testing patterns
- short security concepts
- troubleshooting reminders

Detailed methodology, evidence, and conclusions belong in individual lab READMEs.

---

# 1. Lab Architecture

```text
                         Internet
                            │
                     VirtualBox NAT
                       │          │
                    Kali        Ubuntu
                       │          │
                  eth1 │          │ enp0s8
            192.168.56.10         192.168.56.20
                       └─────┬────┘
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

## Application

```text
https://securebank.lab:3443
```

---

# 2. VirtualBox Networking

## NAT

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

## Host-Only Lab Network

```text
Kali 192.168.56.10
        │
        ▼
192.168.56.0/24
        │
        ▼
Ubuntu 192.168.56.20
```

No default gateway is needed on the lab-only interface.

Mental model:

```text
default route
→ NAT interface

192.168.56.0/24
→ lab interface
```

---

# 3. SecureBank Exposure Model

```text
Kali / external client
        │
        ▼
    Nginx :3443
        │
        ▼
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

Key rule:

```text
container listening
≠
host port published
≠
remotely reachable
```

Publish a host port only when something outside the Docker network needs direct access.

---

# 4. Docker Port Publishing

## All Interfaces

```yaml
ports:
  - "8080:8080"
```

Usually means:

```text
0.0.0.0:8080
[::]:8080
```

Potentially reachable from other hosts unless a firewall blocks it.

## Loopback Only

```yaml
ports:
  - "127.0.0.1:8080:8080"
```

Means:

```text
localhost:8080
    ↓
container:8080
```

Other machines cannot normally connect through the host's lab/LAN address.

## Internal Only

No `ports:` entry required.

```text
web → api:8080
api → postgres:5432
api → keycloak:8080
```

---

# 5. Docker Commands

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

## Exec

```bash
docker exec <container> <command>
```

Example:

```bash
docker exec securebank-web \
  wget -qO- http://securebank-api:8080/health/ready
```

---

# 6. SecureBank Compose

## Local

```bash
docker compose up -d --build
```

## Lab

Always include the lab override when running SecureBank on the Ubuntu target:

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.lab.yml \
  up -d --build
```

Rebuild only the frontend when changing Nginx/frontend configuration:

```bash
docker compose \
  -f docker-compose.yml \
  -f docker-compose.lab.yml \
  up -d --build web
```

Important:

```text
forgetting docker-compose.lab.yml
→ wrong external hostname/proxy behavior
→ Keycloak may generate localhost URLs
```

---

# 7. Linux Networking

## Interfaces

```bash
ip addr
ip -br addr
```

Specific interface:

```bash
ip addr show enp0s8
```

## Routes

```bash
ip route
```

## Connectivity

```bash
ping -c 4 192.168.56.20
ping securebank.lab
```

## Listening Ports

```bash
sudo ss -ltnp
```

Specific port:

```bash
sudo ss -ltnp | grep :22
```

---

# 8. Persistent Kali Lab IP

View connections:

```bash
nmcli connection show
```

Static lab address:

```bash
sudo nmcli connection modify <connection> \
  ipv4.method manual \
  ipv4.addresses 192.168.56.10/24 \
  ipv4.gateway "" \
  ipv4.dns ""
```

Bring connection back up:

```bash
sudo nmcli connection down <connection>
sudo nmcli connection up <connection>
```

Lab interface should have:

```text
192.168.56.10/24
no gateway
no DNS
```

---

# 9. Ubuntu Netplan

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

Apply:

```bash
sudo netplan try
sudo netplan apply
```

---

# 10. Hosts File

```text
192.168.56.20 securebank.lab
```

Test:

```bash
ping securebank.lab
```

---

# 11. SSH

Install:

```bash
sudo apt install -y openssh-server
```

Enable:

```bash
sudo systemctl enable --now ssh
```

Status:

```bash
sudo systemctl status ssh --no-pager
```

Connect:

```bash
ssh nina@192.168.56.20
```

Short timeout:

```bash
ssh -o ConnectTimeout=5 nina@192.168.56.20
```

Mental model:

```text
sshd running
≠
SSH remotely reachable
```

A firewall can block access while the service remains active.

---

# 12. UFW

## Status

```bash
sudo ufw status verbose
sudo ufw status numbered
```

## Defaults

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

## Allow SecureBank

```bash
sudo ufw allow in on enp0s8 to any port 3443 proto tcp
```

## Deny and Log SSH

```bash
sudo ufw deny in on enp0s8 log proto tcp to any port 22
```

## Enable

```bash
sudo ufw enable
```

Important:

```text
firewall filtering
≠
service shutdown
```

and:

```text
block + log
=
prevention + visibility
```

Keep console access available when changing firewall rules remotely.

---

# 13. Firewall Logs

Live kernel log:

```bash
sudo journalctl -kf
```

Search UFW entries:

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

# 14. Nmap

## Default Scan

```bash
nmap 192.168.56.20
```

Does not scan all TCP ports.

## Full TCP Scan

```bash
nmap -p- 192.168.56.20
```

Scans:

```text
1–65535
```

## Version Detection

```bash
nmap -sV -p 22,3443 192.168.56.20
```

## Default NSE Scripts

```bash
nmap -sC -sV -p 22,3443 192.168.56.20
```

## TLS Scripts

```bash
nmap -p 3443 \
  --script ssl-cert,ssl-enum-ciphers \
  192.168.56.20
```

---

# 15. Nmap Port States

```text
open
→ service reachable
```

```text
closed
→ host responds but no service accepts connections
```

```text
filtered
→ filtering prevents Nmap from determining normal service state
```

Important:

```text
service running
≠
port open remotely
```

---

# 16. HTTP Testing with curl

Basic:

```bash
curl http://host/path
```

HTTPS:

```bash
curl https://host/path
```

Ignore self-signed certificate validation:

```bash
curl -k https://securebank.lab:3443
```

Headers only:

```bash
curl -k -I https://securebank.lab:3443
```

Show response headers + body:

```bash
curl -k -i https://securebank.lab:3443/path
```

Compare suspicious paths:

```bash
curl -k -i https://securebank.lab:3443/admin
curl -k -i https://securebank.lab:3443/actuator
curl -k -i https://securebank.lab:3443/this-does-not-exist
```

Useful for validating scanner findings.

---

# 17. HTTP vs HTTPS

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

HTTPS protects application contents in transit.

Network metadata remains visible.

Mental model:

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

# 18. TCP Handshake

```text
SYN
 ↓
SYN/ACK
 ↓
ACK
```

---

# 19. Wireshark Filters

```text
tcp
http
tls
dns
icmp

tcp.port == 8080
ip.addr == 192.168.56.20
```

Follow stream:

```text
Right-click packet
→ Follow
→ TCP Stream
```

---

# 20. TLS with OpenSSL

```bash
openssl s_client \
  -connect securebank.lab:3443 \
  -servername securebank.lab
```

Observed in lab:

```text
TLSv1.3
TLS_AES_256_GCM_SHA384
```

Self-signed certificate:

```text
Verify return code: 18
```

Expected in the controlled lab.

---

# 21. Nginx Version Disclosure

Hardening:

```nginx
server_tokens off;
```

Before:

```text
Server: nginx/1.29.8
```

After:

```text
Server: nginx
```

---

# 22. Nginx SPA Routing

Typical SPA fallback:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

Problem:

```text
unknown path
→ index.html
→ HTTP 200
```

This can create scanner false positives.

Example:

```text
/admin
/actuator
/random-nonexistent-route
```

may all return the same SPA shell.

Mental model:

```text
HTTP 200
≠
resource actually exists
```

---

# 23. File-Like SPA Requests

To avoid serving the SPA for missing file-like resources:

```nginx
location ~ \.[^/]+$ {
    try_files $uri =404;
}
```

Then:

```text
missing .js / .css / .war / .tar / .pem / etc.
→ 404
```

instead of:

```text
→ index.html
→ 200
```

Caveat:

```text
SPA routes containing dots
may be treated as file requests
```

---

# 24. Nginx Location Precedence

Regex locations can override ordinary prefix locations.

For proxied paths that must win over regex matches:

```nginx
location ^~ /api/ {
    ...
}

location ^~ /auth/ {
    ...
}
```

Useful mental model:

```text
^~ prefix
→ stop regex location matching
```

This prevents Keycloak static resources such as:

```text
/auth/resources/.../styles.css
```

from being mistaken for local frontend files.

---

# 25. Nginx Security Header Gotcha

`add_header` behavior depends on location matching and inheritance.

A request may internally redirect:

```text
/
→ /index.html
→ different location
```

and headers can disappear if they are only defined in the original location.

Verify after configuration changes:

```bash
curl -k -I https://securebank.lab:3443/
```

Frontend headers used in the lab include:

```text
X-Content-Type-Options
X-Frame-Options
Referrer-Policy
Permissions-Policy
Content-Security-Policy
```

Do not blindly apply the frontend CSP to Keycloak.

```text
SecureBank frontend CSP
≠
Keycloak CSP requirements
```

---

# 26. Burp Suite

Start:

```bash
burpsuite
```

Useful areas:

```text
Proxy
├── Intercept
├── HTTP history
└── Open browser

Repeater
```

---

# 27. Burp Integrated Browser

```text
Proxy
→ Open browser
```

Useful because proxy configuration is already integrated.

---

# 28. Burp Intercept

With interception enabled:

```text
Browser
   │
   ▼
Burp
   │
   X request paused
```

Actions:

```text
Forward
Drop
```

For general reconnaissance:

```text
login
→ turn Intercept off
→ inspect HTTP history
```

For modification tests:

```text
Intercept on
→ change one value
→ Forward
```

---

# 29. Burp HTTP History

Inspect:

```text
method
URL
status
request headers
request body
response headers
response body
```

Useful filtering target:

```text
/api/
```

---

# 30. Burp Repeater

Use Repeater when you want to:

```text
capture request
→ modify value
→ resend
→ compare response
```

Typical workflow:

```text
HTTP history
→ right-click request
→ Send to Repeater
```

Use fresh values where application state requires them.

Example:

```text
new Idempotency-Key
```

---

# 31. API Recon Workflow

```text
Authenticate normally
        ↓
Browse application
        ↓
Observe /api/ traffic
        ↓
Record endpoints
        ↓
Record methods
        ↓
Inspect query parameters
        ↓
Inspect request bodies
        ↓
Inspect response objects
        ↓
Map object IDs
        ↓
Identify trust boundaries
```

Rule:

```text
map first
test second
```

---

# 32. Bearer Authentication

Observed:

```http
Authorization: Bearer <JWT>
```

Bearer tokens are credentials.

Never commit live values.

Use:

```http
Authorization: Bearer <redacted>
```

---

# 33. JWT Structure

```text
header.payload.signature
```

Useful claims:

```text
iss
aud
sub
exp
iat
azp
realm roles
```

Mental model:

```text
decode token
≠
validate token
```

The API must validate:

```text
signature
issuer
audience
expiry
```

and use identity/claims for authorization.

---

# 34. SecureBank User Context

Collection endpoints may not require a user ID in the URL.

Example:

```http
GET /api/accounts
```

Mental model:

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

Important:

```text
no userId parameter
≠
no authorization risk
```

Object identifiers can still appear in:

```text
URL paths
request bodies
responses
related objects
```

---

# 35. API Object References

## Accounts

```text
account ID
account number
```

## Transfers

```text
transfer ID
sourceAccountId
destinationAccountId
destinationAccountNumber
```

## Beneficiaries

```text
beneficiary ID
accountId
accountNumber
```

---

# 36. Authentication vs Authorization

Authentication:

```text
Who are you?
```

Usually comes from:

```text
JWT
```

Authorization:

```text
Can you perform this action
on this resource?
```

Mental model:

```text
JWT subject
+
resource identifier
+
requested action
↓
authorization decision
```

Authentication alone is not enough.

---

# 37. BOLA / IDOR

BOLA:

```text
Broken Object Level Authorization
```

Basic failure pattern:

```text
authenticated user
      │
      ▼
foreign object ID supplied
      │
      ▼
server fails ownership check
      │
      ▼
unauthorized access
```

Testing pattern:

```text
same authenticated user
same endpoint
same action
different object ID
```

Change as little as possible.

---

# 38. SecureBank Transfer BOLA Test

Endpoint:

```http
POST /api/transfers
```

Relevant body:

```json
{
  "sourceAccountId": "<UUID>",
  "destinationAccountNumber": "<account-number>",
  "amount": 5,
  "currency": "EUR"
}
```

Authorization boundary:

```text
JWT subject
+
sourceAccountId
↓
ownership check
```

Test:

```text
Nina token
+
Alice sourceAccountId
+
fresh Idempotency-Key
↓
403 Forbidden
```

Observed response:

```json
{
  "title": "Access forbidden.",
  "status": 403,
  "detail": "You are not allowed to transfer from this account.",
  "instance": "/api/transfers"
}
```

Result:

```text
ownership enforced
```

---

# 39. Beneficiary BOLA Test

Endpoint:

```http
DELETE /api/beneficiaries/{id}
```

Authorization boundary:

```text
JWT subject
+
beneficiary ID
↓
ownership check
```

Test:

```text
Nina token
+
Alice beneficiary ID
↓
404 Not Found
```

Verification:

```text
Alice beneficiary still existed
```

Result:

```text
unauthorized deletion prevented
```

---

# 40. 403 vs 404 in Authorization Tests

```text
403 Forbidden
→ resource/action recognized
→ caller explicitly denied
```

```text
404 Not Found
→ may be ownership-scoped lookup
→ may avoid revealing foreign object existence
```

Do not judge authorization correctness by status code alone.

Verify whether the protected object was accessed or modified.

---

# 41. Transfer Idempotency

Header:

```http
Idempotency-Key: <UUID>
```

Purpose:

```text
same logical request
+
same key
↓
operation should not execute twice
```

Observed during BOLA testing:

```text
same Idempotency-Key
+
modified request body
↓
original transferId returned
```

Therefore:

```text
reused key
→ request treated as replay
```

For a new authorization test:

```text
use a fresh Idempotency-Key
```

This behavior should be tested separately in a dedicated replay/idempotency lab.

---

# 42. API Query Parameters

Observed for transfer history:

```text
page
pageSize
sortBy
sortDirection
```

Possible validation cases:

```text
page=0
pageSize=very-large
sortBy=invalid
sortDirection=invalid
```

Do not confuse:

```text
reconnaissance
with
testing
```

---

# 43. API Object Graph

```text
User
 │
 ├── Account
 │    └── accountId
 │
 ├── Transfer
 │    ├── transferId
 │    ├── sourceAccountId
 │    └── destinationAccountId
 │
 └── Beneficiary
      ├── beneficiaryId
      └── accountId
```

---

# 44. Automated Security Scanning with fya

Repository environment:

```bash
cd ~/fya
source .venv/bin/activate
```

Version:

```bash
fya --version
```

Detected external tools:

```bash
fya tools
```

Profiles:

```bash
fya scan https://securebank.lab:3443 --profile passive
```

```bash
fya scan https://securebank.lab:3443 --profile safe
```

```bash
fya scan https://securebank.lab:3443 --profile aggressive
```

Rule:

```text
scanner finding
≠
confirmed vulnerability
```

Validate findings manually.

---

# 45. Python Virtual Environment for fya

Create:

```bash
python3 -m venv .venv
```

Activate:

```bash
source .venv/bin/activate
```

Install:

```bash
pip install -e ".[dev]"
```

Useful when Kali blocks system-level pip installs with PEP 668.

---

# 46. fya Findings Observed

Expected / real lab findings included:

```text
self-signed certificate
missing HSTS
missing COOP
missing CORP
missing security.txt
```

Scanner noise included apparent routes/files caused by SPA fallback behavior.

Examples:

```text
/admin
/administrator
/actuator
/actuator/env
/metrics
```

and file-like paths such as:

```text
/backup.tar
/site.war
/database.jks
```

Manual validation is required.

---

# 47. Scanner False-Positive Validation

For suspicious endpoint findings:

```bash
curl -k -i https://securebank.lab:3443/<path>
```

Compare with a deliberately nonexistent path:

```bash
curl -k -i \
  https://securebank.lab:3443/this-definitely-does-not-exist-12345
```

Compare:

```text
status
Content-Type
Content-Length
ETag
response body
```

If responses are identical:

```text
scanner may be detecting SPA fallback
rather than a real endpoint
```

---

# 48. Automated Scanner Mental Model

```text
Scanner
   │
   ▼
candidate finding
   │
   ▼
manual reproduction
   │
   ▼
context analysis
   │
   ▼
confirmed issue
OR
false positive
```

Do not optimize the application only to make the scanner report zero findings.

Fix real problems.

Document scanner limitations.

---

# 49. Security Headers

Useful inspection:

```bash
curl -k -I https://securebank.lab:3443/
```

Common headers:

```text
Strict-Transport-Security
Content-Security-Policy
X-Content-Type-Options
X-Frame-Options
Referrer-Policy
Permissions-Policy
Cross-Origin-Opener-Policy
Cross-Origin-Resource-Policy
```

Remember:

```text
missing header
≠
automatically exploitable vulnerability
```

Interpret in application context.

---

# 50. CSP

SecureBank frontend example:

```text
default-src 'self'
base-uri 'none'
connect-src 'self'
font-src 'self'
form-action 'self'
frame-ancestors 'none'
img-src 'self' data:
object-src 'none'
script-src 'self'
style-src 'self'
```

Keycloak may require different CSP behavior.

Do not impose the SPA policy globally on proxied authentication pages.

---

# 51. Reconnaissance vs Testing

Recon:

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

Same mindset as network enumeration:

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

# 52. Core Security Testing Pattern

```text
Baseline
   ↓
Change one variable
   ↓
Send request
   ↓
Observe response
   ↓
Verify resulting state
   ↓
Interpret control
```

Examples:

```text
own account ID
→ foreign account ID
```

```text
own beneficiary ID
→ foreign beneficiary ID
```

This reduces ambiguity.

---

# 53. Useful Mental Models

```text
container listening
≠
host port published
```

```text
service running
≠
remotely reachable
```

```text
HTTP 200
≠
real resource exists
```

```text
authentication
≠
authorization
```

```text
object identifier
≠
authorization control
```

```text
UUID difficult to guess
≠
ownership enforced
```

```text
scanner finding
≠
confirmed vulnerability
```

```text
blocked service
≠
stopped service
```

```text
decode JWT
≠
validate JWT
```

---

# 54. Quick Commands

## Networking

```bash
ip -br addr
ip route
ping -c 4 <host>
sudo ss -ltnp
```

## Nmap

```bash
nmap <host>
nmap -p- <host>
nmap -sV -p <ports> <host>
nmap -sC -sV -p <ports> <host>
```

## HTTP

```bash
curl -k https://host
curl -k -I https://host
curl -k -i https://host/path
```

## TLS

```bash
openssl s_client \
  -connect host:port \
  -servername hostname
```

## Docker

```bash
docker ps
docker compose ps
docker compose logs --tail=100
docker network inspect <network>
```

## Firewall

```bash
sudo ufw status verbose
sudo ufw status numbered
sudo journalctl -kf
```

## Burp

```text
Proxy → Open browser
Proxy → HTTP history
Proxy → Intercept
Repeater
```

## fya

```bash
source ~/fya/.venv/bin/activate

fya tools

fya scan https://securebank.lab:3443 --profile passive
fya scan https://securebank.lab:3443 --profile safe
fya scan https://securebank.lab:3443 --profile aggressive
```

---

# 55. Lab Lessons

## HTTP vs HTTPS

```text
TLS protects application payloads in transit.
```

## Docker Exposure

```text
A container can listen without being remotely exposed.
```

## Nmap

```text
Enumeration should be progressive.
```

## Firewalling

```text
Filtering controls reachability without necessarily stopping the service.
```

## API Recon

```text
Map objects and trust boundaries before testing them.
```

## BOLA / IDOR

```text
Never trust client-controlled object IDs without server-side authorization.
```

## Automated Scanning

```text
Use scanners to generate hypotheses, then validate them manually.
```

---

# 56. Core Workflow

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

Security tools are evidence-gathering mechanisms.

The security question comes first.