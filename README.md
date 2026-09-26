# Cybersecurity Portfolio

Hands-on security engineering labs exploring how applications and systems can be analyzed, attacked, monitored, and hardened.

## About This Repository

I'm a backend software engineer expanding my skills into cybersecurity and security engineering.

This repository documents practical security work performed in my own lab environments. Rather than serving as a collection of course or CTF write-ups, it focuses on hands-on experiments where I configure systems, generate and analyze traffic, test security controls, investigate vulnerabilities, and document the results.

Each lab is intended to connect security theory with observable behavior in real systems.

## Featured Project

### SecureBank

[SecureBank](https://github.com/Bass-Ninja/SecureBank) is a security-focused banking application built with ASP.NET Core and used as a target environment for some of the labs in this portfolio.

The project provides a realistic environment for exploring topics such as:

- Network traffic analysis
- HTTP and TLS
- Authentication and authorization
- API security
- Identity and access management
- Security monitoring
- Vulnerability testing
- Application hardening

Labs that use SecureBank will reference the relevant application configuration and security controls without duplicating the application source code in this repository.

## Labs

### Network Security

| Lab | Technologies | Topics |
| --- | --- | --- |
| [01 — HTTP vs HTTPS Traffic Analysis](./network-security/01-http-vs-https-traffic-analysis/) | Wireshark, TCP/IP, HTTP, TLS 1.3, Docker | TCP analysis, plaintext exposure, TLS negotiation, encrypted application traffic |

More labs will be added as the portfolio develops.

## Lab Approach

Where appropriate, labs follow a common security engineering workflow:

**Build / Configure → Observe → Test → Analyze → Remediate → Verify**

Each lab documents the environment, methodology, observations, security implications, and lessons learned.

## Current Focus

I'm currently developing deeper practical knowledge in:

- Networking and network security
- Web and API security
- Identity and access management
- Security monitoring and SIEM
- Detection engineering
- Endpoint security

The portfolio will evolve alongside that learning process.
