# Cybersecurity Portfolio

Hands-on security engineering labs exploring how applications and systems can be analyzed, tested, monitored, attacked in controlled environments, and hardened.

## About This Repository

I'm a backend software engineer expanding my skills into cybersecurity and security engineering.

This repository documents practical security work performed in my own lab environments.

Rather than serving as a collection of course notes or CTF write-ups, it focuses on hands-on experiments where I:

- configure systems
- generate and analyze network traffic
- investigate service exposure
- test security controls
- enumerate attack surfaces
- analyze authentication and authorization boundaries
- investigate vulnerabilities
- harden configurations
- verify remediations
- inspect defensive telemetry

The goal is to connect security theory with observable behavior in real systems and understand not only **what** a security control does, but also **how it behaves, how it can be tested, and how its effectiveness can be verified**.

## Featured Project

### SecureBank

[SecureBank](https://github.com/Bass-Ninja/SecureBank) is a security-focused banking application built with ASP.NET Core, PostgreSQL, Keycloak, Nginx, and Docker.

It is used throughout parts of this portfolio as both a realistic target environment and a platform for validating security controls.

SecureBank provides a practical environment for exploring topics such as:

- Network traffic analysis
- TCP/IP and service exposure
- HTTP and TLS
- Authentication and authorization
- Web and API security
- Identity and access management
- Docker network security
- Host firewalling
- Security monitoring
- Vulnerability testing
- Application hardening
- Secure software development
- DevSecOps

The application remains in its own repository.

Labs in this portfolio reference the relevant architecture, configuration, methodology, evidence, and security controls without duplicating the full application source.

## Security Lab Environment

A dedicated isolated lab environment is used for external testing.

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
      Kali attacker        SecureBank target
      192.168.56.10        192.168.56.20
                                  │
                                  ▼
                               Docker
```

The attacker VM uses:

```text
Kali Linux
192.168.56.10
```

The target VM uses:

```text
Ubuntu Server
192.168.56.20
securebank.lab
```

The SecureBank application is exposed to the attacker through:

```text
https://securebank.lab:3443
```

Backend services remain inside the Docker network unless a lab explicitly changes that configuration.

The Ubuntu target also uses host firewall rules to distinguish between the intended public application surface and management access.

Current externally observed behavior from Kali is:

```text
22/tcp   filtered
3443/tcp open
```

SecureBank remains reachable, while SSH management access is blocked from the attacker-facing lab interface.

This makes it possible to test SecureBank from an external perspective without exposing the environment to the normal home network.

## Labs

### Network Security

| Lab | Technologies | Topics |
| --- | --- | --- |
| [01 — HTTP vs HTTPS Traffic Analysis](./network-security/01-http-vs-https-traffic-analysis/) | Wireshark, TCP/IP, HTTP, TLS 1.3, Docker | TCP analysis, plaintext exposure, TLS negotiation, encrypted application traffic |
| [02 — Docker Network Exposure](./network-security/02-docker-network-exposure/) | Docker, Docker Compose, PowerShell, TCP/IP | Port publishing, loopback binding, container networking, attack-surface reduction |
| [03 — Nmap Service Enumeration](./network-security/03-nmap-service-enumeration/) | Kali Linux, Nmap, curl, OpenSSL, Nginx | Full TCP discovery, service fingerprinting, TLS enumeration, HTTP metadata, remediation verification |
| [04 — Host Firewall and Service Segmentation](./network-security/04-firewall-and-segmentation/) | UFW, Linux, Nmap, SSH, curl | Default-deny firewalling, management-plane filtering, service segmentation, firewall logging, verification |

### Reference Material

- [Networking & Security Lab Cheatsheet](./network-security/CHEATSHEET.md)

Additional labs will be added as the portfolio develops.

## Lab Approach

Where appropriate, labs follow a common security engineering workflow:

**Build / Configure → Observe → Test → Analyze → Remediate → Verify**

Depending on the experiment, labs may include:

- architecture and environment
- security objective or hypothesis
- configuration and methodology
- network observations
- attack-surface discovery
- controlled attack or abuse scenarios
- security findings
- packet, HTTP, TLS, firewall, or log evidence
- mitigation or hardening
- verification testing
- lessons learned

The focus is on understanding the complete security lifecycle rather than simply demonstrating individual commands or tools.

## Current Lab Progression

The initial network-security labs deliberately build on one another.

```text
Lab 01
HTTP vs HTTPS traffic analysis
        │
        ▼
Understand what crosses the network
        │
        ▼
Lab 02
Docker network exposure
        │
        ▼
Understand what is reachable
        │
        ▼
Lab 03
Nmap service enumeration
        │
        ▼
Understand what an attacker can discover
        │
        ▼
Lab 04
Host firewall and service segmentation
        │
        ▼
Understand what the attacker should actually be allowed to reach
```

This progression moves from observing network communication to understanding attack surface, external reconnaissance, access control, and defensive visibility.

## Completed Concepts

The portfolio currently includes hands-on work with:

### Network Traffic Analysis

- TCP three-way handshake
- TCP sequence and acknowledgement numbers
- IPv6 loopback traffic
- HTTP request and response inspection
- plaintext bearer-token exposure
- TLS 1.3 negotiation
- encrypted application traffic
- observable TLS/network metadata
- Wireshark filtering and TCP stream reconstruction

### Docker Networking

- host port publishing
- loopback-only port binding
- all-interface port binding
- Docker bridge networking
- internal container DNS
- container-to-container communication
- internal-only service exposure
- PostgreSQL host-port removal
- attack-surface reduction
- verification after hardening

### Reconnaissance and Enumeration

- Nmap default scans
- full TCP port scans
- service/version detection
- Nmap default NSE scripts
- HTTP service enumeration
- TLS certificate enumeration
- TLS cipher enumeration
- OpenSSL connection inspection
- HTTP header inspection
- software-version disclosure analysis
- remediation and rescanning

### Host Firewalling and Service Segmentation

- UFW default policies
- interface-specific firewall rules
- allowing intended public services
- filtering management-plane access
- Nmap `open`, `closed`, and `filtered` states
- SSH reachability testing
- Linux socket inspection
- systemd service verification
- firewall logging
- blocked-connection telemetry
- distinction between service state and network reachability

## Example Security Engineering Findings

The labs are designed to produce concrete observations rather than only demonstrate tooling.

Examples so far include:

### Plaintext HTTP Exposure

A SecureBank API request transmitted over HTTP exposed:

- the request path
- HTTP headers
- the Authorization header
- the bearer token
- response contents

The same request was repeated after enabling TLS and the application data was no longer readable through passive packet inspection.

### Unnecessary PostgreSQL Host Exposure

PostgreSQL was initially published to the host for local debugging.

Testing demonstrated that once the API and database were both containerized, the API could communicate directly with:

```text
postgres:5432
```

The host mapping was removed and application functionality remained intact.

### Nginx Version Disclosure

External enumeration returned:

```text
Server: nginx/1.29.8
```

Nginx was hardened using:

```nginx
server_tokens off;
```

The result was verified:

```text
Server: nginx
```

The exact version was no longer disclosed in normal HTTP responses.

### SSH Management-Plane Exposure

Initial external enumeration from Kali showed:

```text
22/tcp   open
3443/tcp open
```

SSH was reachable from the same lab network as the attacker VM.

The Ubuntu target was hardened with UFW using a default-deny incoming policy.

SecureBank HTTPS remained explicitly allowed:

```bash
sudo ufw allow in on enp0s8 to any port 3443 proto tcp
```

SSH was blocked and logged on the attacker-facing interface:

```bash
sudo ufw deny in on enp0s8 log proto tcp to any port 22
```

After remediation:

```text
22/tcp   filtered
3443/tcp open
```

SecureBank continued to return:

```text
HTTP/1.1 200 OK
```

while the SSH daemon remained active and listening locally.

This demonstrated that network reachability can be reduced without disabling the underlying service.

### Firewall Telemetry

Blocked SSH attempts from Kali generated firewall events containing fields such as:

```text
SRC=192.168.56.10
DST=192.168.56.20
DPT=22
PROTO=TCP
```

This showed that the same control could provide both:

```text
prevention
+
visibility
```

and established a foundation for later SIEM and detection-engineering labs.

## Current Focus

I'm currently developing deeper practical knowledge in:

- Networking and network security
- Linux networking
- Service enumeration
- Host firewalling
- Web and API security
- Identity and access management
- Security monitoring and SIEM
- Detection engineering
- Endpoint security
- Secure software development
- DevSecOps

## Planned Lab Areas

### Network Security

Completed foundational work includes:

- HTTP vs HTTPS traffic analysis
- Docker service exposure
- full TCP service enumeration
- TLS and HTTP metadata enumeration
- host firewall configuration
- management-plane filtering
- verification of filtered versus open ports
- firewall logging

Future network-security extensions may include:

- packet-level analysis of firewall behavior
- `DROP` versus `REJECT` behavior
- dedicated management networks
- separate attacker and management subnets
- routed security zones
- VLAN-based segmentation
- firewall policy between subnets
- forwarding firewall telemetry into a SIEM

### Web and API Security

Planned work includes:

- API reconnaissance
- BOLA/IDOR testing
- broken function-level authorization
- JWT validation
- rate limiting
- replay behavior
- input validation
- mass-assignment testing
- Burp Suite API testing
- CORS and security-header analysis

### Identity and Access Management

Planned work includes:

- Keycloak realm hardening
- role-based access-control testing
- OIDC Authorization Code + PKCE flow analysis
- authentication versus authorization testing
- token-claim inspection

### Security Monitoring

Planned work includes:

- API audit logging
- Wazuh SecureBank monitoring
- firewall-log ingestion
- suspicious-login detection
- API enumeration detection
- repeated authorization-failure detection
- blocked management-access detection
- incident investigation and reporting

### DevSecOps

Planned work includes:

- secret scanning
- dependency scanning
- container scanning
- static analysis
- GitHub Actions security gates
- dynamic application security testing
- software bill of materials generation

### Windows / Active Directory

A future Windows/Active Directory environment will cover:

- domains
- users and groups
- Group Policy
- authentication events
- Windows Event Logs
- privileged-group changes
- PowerShell activity
- SIEM integration

## Portfolio Structure

The repository will grow approximately as:

```text
cybersecurity-portfolio/
├── README.md
│
├── network-security/
│   ├── CHEATSHEET.md
│   ├── 01-http-vs-https-traffic-analysis/
│   ├── 02-docker-network-exposure/
│   ├── 03-nmap-service-enumeration/
│   └── 04-firewall-and-segmentation/
│
├── web-api-security/
│   ├── 01-api-recon-and-attack-surface/
│   ├── 02-bola-idor-testing/
│   ├── 03-broken-function-level-authorization/
│   ├── 04-jwt-token-validation/
│   ├── 05-rate-limiting-and-replay/
│   ├── 06-input-validation-and-mass-assignment/
│   ├── 07-burp-suite-api-testing/
│   ├── 08-security-headers-and-cors/
│   └── 09-api-security-assessment/
│
├── identity-and-access/
│   ├── 01-keycloak-realm-hardening/
│   ├── 02-role-based-access-control/
│   ├── 03-oidc-pkce-flow-analysis/
│   └── 04-authentication-vs-authorization/
│
├── security-monitoring/
│   ├── 01-api-audit-logging/
│   ├── 02-wazuh-securebank-monitoring/
│   ├── 03-suspicious-login-detection/
│   ├── 04-api-enumeration-detection/
│   ├── 05-authorization-failure-detection/
│   ├── 06-rate-limit-abuse-detection/
│   └── 07-incident-report-api-abuse/
│
├── devsecops/
│   ├── 01-secret-scanning/
│   ├── 02-dependency-scanning/
│   ├── 03-container-scanning/
│   ├── 04-semgrep-static-analysis/
│   ├── 05-github-actions-security-pipeline/
│   ├── 06-dast-api-scanning/
│   └── 07-sbom-generation/
│
├── active-directory/
│   └── README.md
│
└── writeups/
    ├── threat-models/
    ├── security-assessments/
    ├── incident-reports/
    ├── vulnerability-research/
    ├── portswigger/
    └── reflections/
```

Directories are added as labs are actually performed rather than pre-populated with empty writeups.

## Documentation Philosophy

Each lab should answer a specific security question.

Examples:

> Can a passive observer read an Authorization bearer token over HTTP?

> Can another machine reach a Docker service bound only to loopback?

> Can the API reach PostgreSQL without exposing the database to the host?

> What services can an attacker discover without knowing the architecture?

> Does a remediation actually change the externally observable result?

> Can the public application remain reachable while management access is blocked?

> Is a blocked service actually stopped, or only inaccessible because of a firewall?

This is preferred over tool-centric writeups such as:

> Learning Wireshark.

or:

> Learning Nmap.

or:

> Learning UFW.

Tools are used to answer security questions rather than being the objective themselves.

## Ethical Scope

All offensive security testing documented in this repository is performed against:

- systems I own
- intentionally created lab environments
- applications where explicit authorization has been granted

The isolated Kali/Ubuntu environment is specifically designed to support controlled security testing without targeting unrelated systems.

## Goal

The goal of this portfolio is to document the transition from backend software engineering into security engineering by demonstrating practical experience across both sides of the security boundary:

```text
Build
  +
Understand architecture
  +
Attack / test
  +
Observe
  +
Detect
  +
Remediate
  +
Verify
```

Rather than treating development and cybersecurity as separate disciplines, the portfolio focuses on how software design, networking, identity, offensive testing, monitoring, and defensive engineering interact in real systems.