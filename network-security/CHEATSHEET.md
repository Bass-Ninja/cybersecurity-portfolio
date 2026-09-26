# Networking & Security Lab Cheatsheet

Commands and mental models collected while building the SecureBank cybersecurity lab environment.

This is intended as a quick personal reference rather than a full tutorial.

---

# 1. Current Lab Architecture

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

### Kali

```text
NAT interface:      eth0
Lab interface:      eth1
Lab IP:             192.168.56.10
```

### Ubuntu target

```text
NAT interface:      enp0s3
Lab interface:      enp0s8
Lab IP:             192.168.56.20
Hostname:           securebank-target
Lab hostname:       securebank.lab
```

---

# 2. Networking Mental Models

## Host vs Container Network

```text
Host published port
    ↓
Allows something outside Docker to reach the container
```

Example:

```yaml
ports:
  - "8080:8080"
```

means:

```text
Host :8080
   ↓
Container :8080
```

---

## Loopback-Only Docker Binding

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

but:

```text
LAN-IP:8080
```

is not reachable through that mapping.

---

## All-Interface Binding

```yaml
ports:
  - "8080:8080"
```

typically appears as:

```text
0.0.0.0:8080->8080/tcp
[::]:8080->8080/tcp
```

Meaning the service is published on host network interfaces rather than only loopback.

---

## No Published Port

```yaml
api:
  # no ports:
```

does **not** mean the service stopped existing.

Containers on the same Docker network can still communicate:

```text
securebank-web
      ↓
http://securebank-api:8080
```

Key rule:

> A container service only needs a published host port when something outside its Docker network needs direct access to it.

---

# 3. Docker Commands

## Running containers

```bash
docker ps
```

or:

```bash
docker compose ps
```

---

## Start stack

```bash
docker compose up -d
```

Build first:

```bash
docker compose up -d --build
```

---

## Recreate one service

```bash
docker compose up -d --force-recreate api
```

Rebuild and recreate:

```bash
docker compose up -d --build --force-recreate web
```

---

## Stop stack

```bash
docker compose down
```

Delete persistent volumes too:

```bash
docker compose down --volumes
```

Use carefully.

---

## Logs

All services:

```bash
docker compose logs --tail=100
```

Specific service:

```bash
docker compose logs api --tail=100
```

---

## Docker networks

List:

```bash
docker network ls
```

Inspect:

```bash
docker network inspect <network-name>
```

Useful information:

```text
container names
container IP addresses
network subnet
connected services
```

---

## Run command inside container

```bash
docker exec <container> <command>
```

Example:

```bash
docker exec securebank-web \
  wget -qO- http://securebank-api:8080/health/ready
```

---

# 4. SecureBank Exposure Model

```text
External / Kali
      │
      ▼
3443 HTTPS
      │
    Nginx
   ┌──┴────────┐
   ▼           ▼
 API        Keycloak
   │
   ▼
PostgreSQL
```

Current intended exposure:

| Port | Service | Exposure |
| ---: | --- | --- |
| `3443` | Web HTTPS / Nginx | Remote |
| `3000` | Web HTTP | Host loopback |
| `8443` | Direct API HTTPS | Host loopback |
| `8080` | API HTTP | Docker only |
| `8081` | Keycloak direct | Host loopback |
| `5432` | PostgreSQL | Docker only |

---

# 5. Windows Port Inspection

Show TCP listener:

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

## Test TCP port

```powershell
Test-NetConnection localhost -Port 15432
```

Important result:

```text
TcpTestSucceeded : True/False
```

---

# 6. Linux Networking Commands

## Interfaces

```bash
ip addr
```

Specific interface:

```bash
ip addr show eth1
```

---

## Routing

```bash
ip route
```

Our Kali routing:

```text
default → eth0 → NAT
192.168.56.0/24 → eth1 → lab
```

Important:

> The default route should remain on the NAT interface.

The internal lab interface does not need a gateway.

---

## Temporary static address

Ubuntu:

```bash
sudo ip addr add 192.168.56.20/24 dev enp0s8
```

Kali:

```bash
sudo ip addr add 192.168.56.10/24 dev eth1
```

These disappear after reboot.

---

# 7. Kali Persistent Address

NetworkManager connections:

```bash
nmcli connection show
```

Set address:

```bash
sudo nmcli connection modify eth1 \
  ipv4.method manual \
  ipv4.addresses 192.168.56.10/24 \
  ipv4.gateway ""
```

Restart connection:

```bash
sudo nmcli connection down eth1
sudo nmcli connection up eth1
```

---

# 8. Ubuntu Persistent Address

Ubuntu uses Netplan.

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

Do not configure a second default gateway on the lab interface.

---

# 9. Connectivity Testing

Ping Ubuntu from Kali:

```bash
ping -c 4 192.168.56.20
```

Ping Kali from Ubuntu:

```bash
ping -c 4 192.168.56.10
```

---

# 10. SSH

Install server on Ubuntu:

```bash
sudo apt install -y openssh-server
```

Enable:

```bash
sudo systemctl enable --now ssh
```

Connect from Kali:

```bash
ssh nina@192.168.56.20
```

Exit:

```bash
exit
```

Closing SSH does not stop Ubuntu or Docker.

---

# 11. Hostname Resolution

Kali `/etc/hosts`:

```text
192.168.56.20 securebank.lab
```

Add:

```bash
echo '192.168.56.20 securebank.lab' |
  sudo tee -a /etc/hosts
```

Test:

```bash
ping securebank.lab
```

---

# 12. HTTP / HTTPS Testing

HTTP request:

```bash
curl http://host:port/path
```

HTTPS:

```bash
curl https://host/path
```

Ignore certificate verification in controlled lab:

```bash
curl -k https://securebank.lab:3443
```

Headers only:

```bash
curl -k -I https://securebank.lab:3443
```

`-k` should only be necessary here because the lab certificate is self-signed/untrusted.

---

# 13. HTTP vs HTTPS

## HTTP

```text
TCP
 ↓
HTTP plaintext
```

Packet capture can reveal:

```text
HTTP method
path
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
HTTP encrypted inside TLS
```

Passive capture can still reveal metadata such as:

```text
IP addresses
ports
packet sizes
timing
TLS handshake
TLS version
cipher suite
certificate information
```

but not normal HTTP contents without decryption material.

---

# 14. TCP Handshake

```text
Client → Server   SYN
Server → Client   SYN/ACK
Client → Server   ACK
```

Then application data can be transmitted.

Mental model:

```text
Sequence number
= where my outgoing bytes begin

Acknowledgement number
= next byte I expect from you
```

SYN consumes one sequence number.

---

# 15. Wireshark Filters

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

Port:

```text
tcp.port == 8080
```

IP:

```text
ip.addr == 192.168.56.20
```

---

# 16. Nmap Basics

## Default scan

```bash
nmap 192.168.56.20
```

Checks common TCP ports.

Important:

> A default scan can miss services running on less common ports.

---

## All TCP ports

```bash
nmap -p- 192.168.56.20
```

Scans ports:

```text
1–65535
```

---

## Service/version detection

```bash
nmap -sV -p 22,3443 192.168.56.20
```

---

## Aggressive version probing

```bash
nmap -sV --version-all -p 3443 192.168.56.20
```

---

## Default scripts

```bash
nmap -sC -sV -p 22,3443 192.168.56.20
```

Useful for additional safe enumeration.

---

# 17. Nmap TLS Enumeration

Certificate:

```bash
nmap -p 3443 \
  --script ssl-cert \
  192.168.56.20
```

Ciphers:

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

---

# 18. OpenSSL TLS Inspection

```bash
openssl s_client \
  -connect securebank.lab:3443 \
  -servername securebank.lab
```

Useful fields:

```text
certificate subject
certificate issuer
certificate validity
TLS protocol
negotiated cipher
key exchange group
verification result
```

Our lab certificate returns:

```text
Verify return code: 18
```

because it is self-signed.

Expected in the lab.

---

# 19. Nginx Version Disclosure

Before hardening:

```text
Server: nginx/1.29.8
```

Configuration:

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

# 20. Security Headers Seen in SecureBank

```text
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: no-referrer
Permissions-Policy
Content-Security-Policy
```

These are separate from TLS.

TLS protects communication in transit.

Security headers control aspects of browser behavior.

---

# 21. Core Enumeration Workflow

```text
Identify target
      ↓
Check connectivity
      ↓
Default scan
      ↓
Full port scan
      ↓
Service detection
      ↓
Protocol-specific enumeration
      ↓
Interpret findings
      ↓
Remediate
      ↓
Rescan
```

Do not jump directly to known application ports during reconnaissance.

The point is to discover the target's exposed surface rather than reproduce prior knowledge.

---

# 22. Core Security Engineering Workflow

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

This is the recurring workflow across the SecureBank labs.

---

# 23. Lessons From Labs 01–03

### Lab 01 — HTTP vs HTTPS

Authentication does not provide transport confidentiality.

```text
Bearer token over HTTP
→ observable in packet capture

Bearer token over HTTPS
→ protected by TLS
```

### Lab 02 — Docker Exposure

```text
container listening
≠
service publicly reachable
```

Container-to-container communication does not require host port publishing.

### Lab 03 — Enumeration

```text
service deployed
≠
service discovered by default scan
```

Reconnaissance is progressive.

Each discovery determines the next enumeration step.

---

# 24. Commands Worth Memorizing

```bash
ip addr
ip route

ping -c 4 <host>

ssh user@host

docker compose ps
docker compose logs --tail=100
docker network ls
docker network inspect <network>

curl -k https://host
curl -k -I https://host

nmap <host>
nmap -p- <host>
nmap -sV -p <ports> <host>
nmap -sC -sV -p <ports> <host>

openssl s_client -connect host:port -servername hostname
```

The goal is not to memorize every tool option.

The important part is understanding **why** each command is being used.