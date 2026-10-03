# Cybersecurity Portfolio

Hands-on security engineering labs focused on analyzing, testing, and hardening application and infrastructure behavior.

## About

I'm a backend software engineer expanding into cybersecurity and security engineering.

This repository documents practical work performed in controlled lab environments, with an emphasis on:

- network security
- web and API security
- authentication and authorization
- IAM and OIDC
- secure application architecture
- automated security testing
- DevSecOps
- security monitoring

The goal is to build practical security skills by working with real systems rather than isolated theory.

---

## Featured Project — SecureBank

[SecureBank](https://github.com/Bass-Ninja/SecureBank) is a security-focused banking application built with:

- ASP.NET Core
- PostgreSQL
- Keycloak
- Nginx
- Docker

It is used throughout this portfolio as the primary application and security target.

The project provides a realistic environment for exploring:

- HTTP and TLS
- Docker networking
- service exposure
- OIDC and JWT authentication
- role-based access control
- object-level authorization
- API security
- host firewalling
- application hardening
- automated security testing

The SecureBank application remains in its own repository. This portfolio contains the related security labs, evidence, and write-ups.

---

## Lab Environment

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

**Attacker**

```text
Kali Linux
192.168.56.10
```

**Target**

```text
Ubuntu Server
192.168.56.20
securebank.lab
```

**Application**

```text
https://securebank.lab:3443
```

Backend services remain inside Docker unless intentionally exposed for a lab.

---

## Labs

### Network Security

| Lab | Technologies | Focus |
| --- | --- | --- |
| [01 — HTTP vs HTTPS Traffic Analysis](./network-security/01-http-vs-https-traffic-analysis/) | Wireshark, TCP/IP, HTTP, TLS | Plaintext exposure, TCP analysis, TLS |
| [02 — Docker Network Exposure](./network-security/02-docker-network-exposure/) | Docker, Docker Compose, TCP/IP | Port publishing, loopback binding, attack-surface reduction |
| [03 — Nmap Service Enumeration](./network-security/03-nmap-service-enumeration/) | Kali Linux, Nmap, curl, OpenSSL | Port discovery, service fingerprinting, TLS enumeration |
| [04 — Host Firewall and Service Segmentation](./network-security/04-firewall-and-segmentation/) | UFW, Linux, Nmap, SSH | Firewall rules, management-plane filtering, logging |

### Web & API Security

| Lab | Technologies | Focus |
| --- | --- | --- |
| [01 — API Reconnaissance and Attack-Surface Mapping](./web-api-security/01-api-recon-and-attack-surface/) | Burp Suite, REST, JWT, Keycloak | Authenticated reconnaissance, endpoint and object mapping |
| [02 — BOLA / IDOR Testing](./web-api-security/02-bola-idor-testing/) | Burp Suite, Repeater, JWT | Object-level authorization and cross-user ownership testing |
| [03 — Automated Security Scanning and False-Positive Validation](./web-api-security/03-automated-security-scanning/) | fya, Nikto, curl, Nginx | DAST, scanner validation, false-positive analysis |

### Reference Material

- [Cybersecurity Lab Cheatsheet](./network-security/CHEATSHEET.md)

---

## Skills Demonstrated

### Network Security

- TCP/IP fundamentals
- Wireshark traffic analysis
- HTTP and TLS inspection
- Nmap enumeration
- service fingerprinting
- OpenSSL
- Docker networking
- network exposure analysis
- UFW firewalling
- firewall logging

### Web & API Security

- Burp Suite Proxy and Repeater
- authenticated API reconnaissance
- REST API analysis
- JWT inspection
- object-level authorization testing
- BOLA / IDOR testing
- API trust-boundary analysis
- DAST
- manual validation of automated findings

### Application Security

- authentication vs authorization
- OIDC / Keycloak
- JWT-based identity
- role-based access control
- object ownership validation
- security headers
- Nginx hardening
- attack-surface reduction

### Development

- C#
- ASP.NET Core
- PostgreSQL
- Docker
- Nginx
- Git
- REST APIs

---

## Methodology

The recurring workflow used throughout the portfolio is:

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

Each lab is built around a concrete security question.

Detailed commands, evidence, results, reasoning, and remediation steps are kept in the individual lab READMEs.

---

## Current Direction

Planned areas include:

- broken function-level authorization
- JWT validation
- replay and idempotency testing
- rate limiting
- malformed input and mass assignment
- Keycloak hardening
- secret scanning
- dependency scanning
- container scanning
- static analysis
- SIEM and detection engineering

---

## Ethical Scope

Testing is restricted to:

- systems I own
- intentionally created lab environments
- systems where explicit authorization exists

The Kali and Ubuntu environment used throughout this repository is deliberately isolated for controlled security testing.

---

## Goal

This portfolio documents my transition from backend development into security engineering.

The goal is to combine software-development experience with practical security work across networking, identity, application security, testing, hardening, and monitoring.