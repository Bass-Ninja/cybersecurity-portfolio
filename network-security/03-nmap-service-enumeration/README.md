# Lab 03 — Nmap Service Enumeration

## Overview

This lab examines the externally visible attack surface of the SecureBank target environment from a separate Kali Linux attacker VM.

The previous Docker networking lab defined which services were intended to be externally reachable and which should remain internal.

This lab approaches the environment from the opposite perspective:

> What can a host on the attacker network actually discover without prior knowledge of the SecureBank architecture?

The experiment uses Nmap, curl, and OpenSSL to progressively discover open ports, fingerprint services, inspect HTTP response metadata, analyze the TLS endpoint, and identify a small information-disclosure hardening opportunity.

## Lab Summary

**Objective:** Enumerate the SecureBank target from an attacker VM and compare the observed attack surface with the intended architecture.

**Target:** `securebank.lab` (`192.168.56.20`)

**Attacker:** Kali Linux (`192.168.56.10`)

**Key findings:**

- SSH was visible on TCP port `22`.
- The SecureBank HTTPS application was exposed on non-standard TCP port `3443`.
- The default Nmap scan did not initially discover the application service.
- A full TCP port scan revealed port `3443`.
- Service detection identified OpenSSH and Nginx, including their versions.
- TLS and certificate metadata were observable remotely.
- Nginx exposed its exact version through the HTTP `Server` header.
- Nginx version disclosure was reduced using `server_tokens off;`.

**Technologies:** Kali Linux, Ubuntu Server, VirtualBox, Nmap, curl, OpenSSL, Nginx, Docker, TLS

---

## Lab Architecture

The environment consists of two VirtualBox virtual machines connected through an isolated internal network.

```text
                     Internet
                        │
                 VirtualBox NAT
                   │         │
                   │         │
                Kali       Ubuntu
                   │         │
                   └────┬────┘
                        │
                 securebank-lab
                 192.168.56.0/24
                        │
             ┌──────────┴──────────┐
             │                     │
     Kali attacker          SecureBank target
     192.168.56.10          192.168.56.20
                                   │
                                   ▼
                                Docker
                                   │
                           Nginx / SecureBank
```

The target is referenced from Kali using:

```text
securebank.lab
```

which resolves to:

```text
192.168.56.20
```

The intended externally reachable application entry point is:

```text
https://securebank.lab:3443
```

Backend services such as PostgreSQL and the API's internal HTTP listener remain inside the Docker network.

---

## 1. Basic Nmap Scan

The first scan was performed without specifying ports or service knowledge:

```bash
nmap 192.168.56.20
```

Result:

```text
PORT   STATE SERVICE
22/tcp open  ssh
```

Nmap reported the host as reachable but showed only SSH.

### Observation

The SecureBank application was known to be reachable on port `3443`, but it did not appear in this initial scan.

This demonstrated an important limitation of relying only on a default Nmap scan.

A default TCP scan checks Nmap's commonly used port set rather than every possible TCP port.

A service listening on a less commonly scanned port may therefore remain undiscovered.

---

## 2. Full TCP Port Scan

To remove that assumption, all TCP ports were scanned:

```bash
nmap -p- 192.168.56.20
```

Result:

```text
22/tcp   open  ssh
3443/tcp open  ov-nnm-websrv
```

The full scan revealed the SecureBank application listener on port `3443`.

At this stage, Nmap knew that a service was listening but had not yet accurately identified the application protocol.

### Key Observation

```text
Default scan
    ↓
22/tcp discovered

Full TCP scan
    ↓
22/tcp + 3443/tcp discovered
```

This demonstrated why broader port discovery can be necessary before performing detailed service enumeration.

---

## 3. Service and Version Detection

Once the open ports were discovered, service detection was performed only against those ports:

```bash
nmap -sV -p 22,3443 192.168.56.20
```

Result:

```text
22/tcp   open  ssh      OpenSSH 10.2p1 Ubuntu 2ubuntu3.6
3443/tcp open  ssl/http nginx 1.29.8
```

Nmap identified:

```text
22/tcp
OpenSSH 10.2p1
Ubuntu Linux

3443/tcp
HTTPS
nginx 1.29.8
```

More aggressive version probing against the web service produced the same result:

```bash
nmap -sV --version-all -p 3443 192.168.56.20
```

### Security Implication

Service fingerprinting provides an attacker with information that can be used during later reconnaissance.

Knowing the exact product and version allows the tester to research:

- known vulnerabilities
- version-specific behavior
- default configurations
- common misconfigurations

Service detection itself does not establish that a vulnerability exists.

---

## 4. Default Nmap Script Enumeration

Nmap's default safe script set was run against the discovered services:

```bash
nmap -sC -sV -p 22,3443 192.168.56.20
```

The scan identified:

```text
22/tcp   OpenSSH 10.2p1
3443/tcp nginx 1.29.8
```

It also identified:

```text
HTTP title: SecureBank
TLS certificate CN: securebank.lab
ALPN support
TLS certificate validity dates
certificate Subject Alternative Names
```

The certificate exposed the following SAN values:

```text
DNS:securebank.lab
DNS:localhost
IP:127.0.0.1
IP:192.168.56.20
```

### Observation

TLS encrypts application data but does not hide all connection metadata.

An unauthenticated remote observer can still learn information about:

- the web server
- the TLS endpoint
- certificate names
- certificate validity
- supported protocol behavior
- network service availability

---

## 5. TLS Enumeration

TLS configuration was enumerated using Nmap:

```bash
nmap -p 3443 \
  --script ssl-cert,ssl-enum-ciphers \
  192.168.56.20
```

The server supported:

```text
TLS 1.2
TLS 1.3
```

The TLS 1.3 cipher suites included:

```text
TLS_AES_128_GCM_SHA256
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256
```

Nmap rated the least cipher strength observed as:

```text
A
```

The certificate used:

```text
RSA 2048-bit key
SHA-256 signature
```

The certificate was self-signed because it was generated specifically for the isolated lab environment.

---

## 6. OpenSSL TLS Inspection

The HTTPS endpoint was inspected directly using OpenSSL:

```bash
openssl s_client \
  -connect securebank.lab:3443 \
  -servername securebank.lab
```

The negotiated connection used:

```text
Protocol: TLSv1.3
Cipher: TLS_AES_256_GCM_SHA384
```

The negotiated TLS 1.3 group was:

```text
X25519MLKEM768
```

The certificate verification result was:

```text
Verify return code: 18 (self-signed certificate)
```

This was expected because the certificate was generated locally and Kali does not trust its issuer.

A production deployment would normally use a certificate chaining to a trusted certificate authority.

---

## 7. HTTP Header Inspection

HTTP response headers were inspected using:

```bash
curl -k -I https://securebank.lab:3443
```

The response initially included:

```text
HTTP/1.1 200 OK
Server: nginx/1.29.8
```

The response also contained several application security headers:

```text
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: no-referrer
Permissions-Policy: camera=(), geolocation=(), microphone=()
Content-Security-Policy: ...
```

### Positive Security Observation

The frontend response included restrictive browser security headers, including:

- Content Security Policy
- clickjacking protection
- MIME-sniffing protection
- restrictive referrer policy
- browser permissions restrictions

---

## Security Observation — Nginx Version Disclosure

### Observation

The HTTP response disclosed the exact Nginx version:

```text
Server: nginx/1.29.8
```

Nmap was also able to identify the same version remotely.

### Security Impact

Exact software version disclosure is not a vulnerability by itself.

However, unnecessary version information can simplify reconnaissance by allowing an attacker to immediately correlate the exposed service with:

- publicly documented vulnerabilities
- version-specific behavior
- known configuration weaknesses

Removing unnecessary version detail reduces information available during reconnaissance.

---

## Remediation

The Nginx configuration was updated with:

```nginx
server_tokens off;
```

This prevents Nginx from including its exact version in standard response headers and generated error pages.

The web container was rebuilt and recreated.

---

## Verification

The response headers were tested again:

```bash
curl -k -I https://securebank.lab:3443
```

Before remediation:

```text
Server: nginx/1.29.8
```

After remediation:

```text
Server: nginx
```

The exact Nginx version was therefore no longer disclosed through the normal HTTP `Server` header.

The service can still be identified as Nginx, but unnecessary version detail has been removed.

---

## Observed External Attack Surface

From the Kali attacker VM, the discovered TCP attack surface was:

| Port | Service | Exposure |
| ---: | --- | --- |
| `22` | OpenSSH | Reachable |
| `3443` | SecureBank HTTPS / Nginx | Reachable |
| `5432` | PostgreSQL | Not reachable |
| `8080` | API HTTP | Not reachable |
| `8081` | Direct Keycloak HTTP | Not reachable |
| `8443` | Direct API HTTPS | Not reachable |

This matched the intended Docker exposure model from the previous lab.

The application remained accessible through its intended public entry point while backend service ports were not visible to the attacker VM.

---

## SSH Observation

SSH was reachable from the attacker network:

```text
22/tcp open ssh
```

This is currently intentional because SSH is used to administer the Ubuntu target VM.

However, the presence of a management service on the same network as the attacker represents an additional attack surface.

A future firewall and segmentation lab will evaluate whether Kali should be permitted to reach SSH at all.

---

## Enumeration Workflow

The experiment followed a progressive reconnaissance process:

```text
Target identified
      ↓
Default port scan
      ↓
Full TCP port scan
      ↓
Open ports discovered
      ↓
Service/version detection
      ↓
Protocol-specific enumeration
      ↓
HTTP/TLS metadata inspection
      ↓
Hardening opportunity identified
      ↓
Remediation
      ↓
Retest
```

This approach avoids relying on prior knowledge of the target's implementation.

---

## Key Takeaways

Through this lab I practiced:

- performing basic Nmap reconnaissance
- distinguishing default and full TCP port scans
- discovering services running on non-standard ports
- performing service and version detection
- using Nmap NSE scripts for additional enumeration
- identifying operating-system and service metadata
- inspecting TLS certificate information
- enumerating supported TLS protocols and cipher suites
- inspecting a TLS connection with OpenSSL
- retrieving HTTP headers with curl
- identifying unnecessary server-version disclosure
- hardening Nginx configuration
- verifying remediation through repeated enumeration
- comparing externally observed services with intended Docker exposure
- thinking about management services such as SSH as part of the attack surface

---

## Conclusion

This lab demonstrated how an attacker can progressively enumerate a target without prior knowledge of its internal architecture.

The initial default Nmap scan discovered only SSH and did not reveal the SecureBank application running on port `3443`.

A full TCP scan identified the additional service, after which service detection correctly fingerprinted Nginx and OpenSSH.

Further enumeration exposed TLS certificate metadata, supported protocols, cryptographic configuration, application identity, and HTTP response headers.

The experiment also identified an unnecessary information-disclosure condition: the exact Nginx version was exposed through the HTTP `Server` header.

After adding `server_tokens off;`, the endpoint was retested and the precise version was no longer disclosed.

The lab reinforces that enumeration is not a single scan but a progressive process in which each observation informs the next test.