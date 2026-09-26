# Cybersecurity Portfolio

Hands-on security engineering labs exploring how applications and systems can be analyzed, tested, monitored, attacked in controlled environments, and hardened.

## About This Repository

I'm a backend software engineer expanding my skills into cybersecurity and security engineering.

This repository documents practical security work performed in my own lab environments.

Rather than serving as a collection of course notes or CTF write-ups, it focuses on hands-on experiments where I:

- configure systems
- generate and analyze network traffic
- investigate service exposure
- enumerate attack surfaces
- inspect authenticated API behavior
- map object and trust boundaries
- test security controls
- analyze authentication and authorization
- harden configurations
- inspect defensive telemetry
- verify remediations

The goal is to connect security theory with observable behavior in real systems and understand not only **what** a security control does, but also **how it behaves, how it can be tested, and how its effectiveness can be verified**.

## Featured Project

### SecureBank

[SecureBank](https://github.com/Bass-Ninja/SecureBank) is a security-focused banking application built with ASP.NET Core, PostgreSQL, Keycloak, Nginx, and Docker.

It is used throughout the portfolio as both:

```text
application
+
security target
```

SecureBank provides a practical environment for exploring:

- TCP/IP
- HTTP
- TLS
- Docker networking
- service exposure
- host firewalling
- API security
- authentication
- authorization
- OIDC
- JWT
- object-level authorization
- security monitoring
- application hardening
- DevSecOps

The application remains in its own repository.

The portfolio contains the security methodology, evidence, findings, and writeups generated while assessing it.

## Security Lab Environment

```text
                    Internet
                       │
                VirtualBox NAT
                  │         │
               Kali       Ubuntu
                  │         │
                  └────┬────┘
                       │
                securebank-lab
                192.168.56.0/24
```

Attacker:

```text
Kali Linux
192.168.56.10
```

Target:

```text
Ubuntu Server
192.168.56.20
securebank.lab
```

Application:

```text
https://securebank.lab:3443
```

Current external service state from Kali:

```text
22/tcp   filtered
3443/tcp open
```

Backend services remain inside Docker.

## Labs

### Network Security

| Lab | Technologies | Topics |
| --- | --- | --- |
| [01 — HTTP vs HTTPS Traffic Analysis](./network-security/01-http-vs-https-traffic-analysis/) | Wireshark, TCP/IP, HTTP, TLS 1.3, Docker | TCP analysis, plaintext exposure, TLS negotiation, encrypted traffic |
| [02 — Docker Network Exposure](./network-security/02-docker-network-exposure/) | Docker, Docker Compose, PowerShell, TCP/IP | Port publishing, loopback binding, container networking, attack-surface reduction |
| [03 — Nmap Service Enumeration](./network-security/03-nmap-service-enumeration/) | Kali Linux, Nmap, curl, OpenSSL, Nginx | Full-port discovery, fingerprinting, TLS enumeration, HTTP metadata |
| [04 — Host Firewall and Service Segmentation](./network-security/04-firewall-and-segmentation/) | UFW, Linux, Nmap, SSH, curl | Default deny, management-plane filtering, firewall logging, verification |

### Web & API Security

| Lab | Technologies | Topics |
| --- | --- | --- |
| [01 — API Reconnaissance and Attack-Surface Mapping](./web-api-security/01-api-recon-and-attack-surface/) | Burp Suite, HTTP, REST, JWT, Keycloak | Authenticated reconnaissance, endpoint discovery, object mapping, authorization-boundary identification |

### Reference Material

- [Cybersecurity Lab Cheatsheet](./network-security/CHEATSHEET.md)

## Lab Approach

The recurring workflow is:

**Build / Configure → Observe → Test → Analyze → Remediate → Verify**

Depending on the lab, evidence may include:

- packet captures
- Nmap output
- HTTP requests
- HTTP responses
- TLS metadata
- firewall events
- API bodies
- JWT claims
- application logs
- SIEM events

## Current Lab Progression

```text
Lab 01
HTTP vs HTTPS
      │
      ▼
What crosses the network?
      │
      ▼
Lab 02
Docker Network Exposure
      │
      ▼
What is reachable?
      │
      ▼
Lab 03
Nmap Enumeration
      │
      ▼
What can an attacker discover?
      │
      ▼
Lab 04
Host Firewall and Service Segmentation
      │
      ▼
What should be reachable?
      │
      ▼
Lab 05
API Reconnaissance
      │
      ▼
What application surface exists behind HTTPS?
      │
      ▼
Next:
BOLA / IDOR Testing
```

The progression deliberately moves upward through the stack rather than treating tools as unrelated exercises.

## Completed Concepts

### Network Traffic Analysis

- TCP handshake
- sequence and acknowledgement numbers
- HTTP inspection
- plaintext bearer-token exposure
- TLS negotiation
- encrypted application traffic
- observable network metadata
- Wireshark filters
- TCP stream reconstruction

### Docker Networking

- host port publishing
- loopback binding
- all-interface binding
- bridge networking
- Docker DNS
- internal container communication
- database exposure reduction
- host attack-surface reduction

### Reconnaissance

- default Nmap scanning
- full TCP scanning
- service/version detection
- NSE scripts
- TLS certificate enumeration
- cipher enumeration
- OpenSSL inspection
- HTTP header analysis

### Firewalling

- default-deny inbound policy
- interface-specific rules
- management-plane filtering
- Nmap filtered-state verification
- service-state verification
- firewall logging
- prevention vs visibility

### API Reconnaissance

- Burp Proxy
- HTTP history
- authenticated reconnaissance
- OIDC flow observation
- Bearer JWT inspection
- endpoint discovery
- request-body analysis
- query-parameter mapping
- object identifier mapping
- object-relationship mapping
- authorization-boundary identification
- replay/idempotency candidate identification

## Example Security Engineering Findings

### Plaintext HTTP Exposure

HTTP exposed:

- request path
- headers
- bearer token
- response data

TLS prevented passive inspection of application contents.

### PostgreSQL Host Exposure

The host database mapping was unnecessary once both the API and database ran inside Docker.

It was removed while preserving:

```text
api → postgres:5432
```

### Nginx Version Disclosure

Before:

```text
Server: nginx/1.29.8
```

After:

```text
Server: nginx
```

### SSH Management Exposure

Before:

```text
22/tcp open
```

After UFW:

```text
22/tcp filtered
```

while:

```text
sshd remains active
```

### API Object Authorization Boundaries

Burp reconnaissance identified:

```text
POST /api/transfers
→ sourceAccountId
```

and:

```text
DELETE /api/beneficiaries/{id}
→ beneficiaryId
```

as client-controlled resource identifiers requiring server-side ownership checks.

### Transfer Replay Boundary

Transfer requests include:

```http
Idempotency-Key: <UUID>
```

providing a separate future test for replay resistance.

## Current Focus

Current study areas include:

- networking
- Linux
- service enumeration
- host firewalling
- web/API security
- Burp Suite
- authentication
- authorization
- IAM
- JWT/OIDC
- SIEM
- detection engineering
- secure software development
- DevSecOps

## Planned Lab Areas

### Web & API Security

Next:

- BOLA/IDOR testing
- transfer-source ownership tests
- beneficiary ownership tests
- broken function-level authorization
- JWT validation
- replay/idempotency
- rate limiting
- malformed input
- CORS
- security headers

### Identity and Access

Planned:

- Keycloak hardening
- role testing
- OIDC/PKCE analysis
- authentication vs authorization
- token claim validation

### Security Monitoring

Planned:

- API audit logging
- Wazuh ingestion
- firewall-log ingestion
- login detection
- API enumeration detection
- authorization-failure detection
- incident investigation

### DevSecOps

Planned:

- secret scanning
- dependency scanning
- container scanning
- static analysis
- GitHub Actions security gates
- DAST
- SBOM generation

### Network Security Extensions

Potential future work:

- firewall packet analysis
- DROP vs REJECT
- separate management subnet
- routed zones
- VLAN segmentation

### Windows / Active Directory

Future environment:

- domains
- users/groups
- Group Policy
- Windows authentication events
- PowerShell
- privileged changes
- SIEM integration

## Portfolio Structure

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

Directories are added as the labs are actually performed.

## Documentation Philosophy

Every lab should answer a security question.

Good examples:

> Can a passive observer read a bearer token over HTTP?

> Can another host reach a Docker service bound only to loopback?

> What services can an attacker discover without prior architecture knowledge?

> Can SecureBank stay reachable while SSH management access is blocked?

> What API objects and authorization boundaries can an authenticated tester discover?

Less useful framing:

> Learning Nmap.

> Learning Burp.

> Learning UFW.

Tools are mechanisms for answering security questions.

## Ethical Scope

Testing is restricted to:

- systems I own
- intentionally created labs
- environments where explicit authorization exists

The Kali/Ubuntu environment is deliberately isolated for controlled security testing.

## Goal

The portfolio documents the transition from backend development into security engineering by demonstrating both sides of a system:

```text
Build
  +
Understand
  +
Observe
  +
Enumerate
  +
Attack / test
  +
Detect
  +
Remediate
  +
Verify
```

The goal is not to separate development and security, but to understand how architecture, code, networking, identity, offensive testing, monitoring, and defensive controls interact.