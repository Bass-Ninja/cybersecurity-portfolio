# Cybersecurity Portfolio

Hands-on security engineering labs exploring how applications and systems can be analyzed, tested, monitored, attacked in controlled environments, and hardened.

## About This Repository

I'm a backend software engineer expanding my skills into cybersecurity and security engineering.

This repository documents practical security work performed in my own lab environments. Rather than serving as a collection of course notes or CTF write-ups, it focuses on hands-on experiments where I configure systems, generate and analyze traffic, test security controls, investigate vulnerabilities, and document the results.

The goal is to connect security theory with observable behavior in real systems and understand not only **what** a security control does, but also **how it behaves, how it can be tested, and how its effectiveness can be verified**.

## Featured Project

### SecureBank

[SecureBank](https://github.com/Bass-Ninja/SecureBank) is a security-focused banking application built with ASP.NET Core.

It is used throughout parts of this portfolio as both a realistic target environment and a platform for validating security controls.

SecureBank provides a practical environment for exploring topics such as:

- Network traffic analysis
- HTTP, TCP, and TLS
- Authentication and authorization
- Web and API security
- Identity and access management
- Security monitoring
- Vulnerability testing
- Application hardening
- Secure software development
- DevSecOps

Labs that use SecureBank reference the relevant application configuration and security controls without duplicating the application source code in this repository.

## Labs

### Network Security

| Lab | Technologies | Topics |
| --- | --- | --- |
| [01 — HTTP vs HTTPS Traffic Analysis](./network-security/01-http-vs-https-traffic-analysis/) | Wireshark, TCP/IP, HTTP, TLS 1.3, Docker | TCP analysis, plaintext exposure, TLS negotiation, encrypted application traffic |
| [02 — Docker Network Exposure](./network-security/02-docker-network-exposure/) | Docker, Docker Compose, PowerShell, TCP/IP | Port publishing, loopback binding, container networking, attack surface reduction |

Additional labs will be added as the portfolio develops.

## Lab Approach

Where appropriate, labs follow a common security engineering workflow:

**Build / Configure → Observe → Test → Analyze → Remediate → Verify**

Depending on the type of experiment, labs may include:

- Lab architecture and environment
- Security objective or hypothesis
- Configuration and methodology
- Network or application observations
- Attack or abuse scenarios
- Security findings
- Logs and packet evidence
- Mitigation or hardening
- Verification testing
- Lessons learned

The focus is on understanding the complete security lifecycle rather than simply demonstrating individual tools or commands.

## Current Focus

I'm currently developing deeper practical knowledge in:

- Networking and network security
- Web and API security
- Identity and access management
- Security monitoring and SIEM
- Detection engineering
- Endpoint security
- Secure software development
- DevSecOps

The portfolio will evolve alongside that learning process as new concepts are applied in practical lab environments.