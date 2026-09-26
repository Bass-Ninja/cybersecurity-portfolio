# Lab 04 — Host Firewall and Service Segmentation

## Overview

This lab examines how host-based firewall rules can reduce the externally reachable attack surface of the SecureBank target without stopping the underlying services.

The previous service-enumeration lab showed that a host on the isolated security-testing network could discover:

```text
22/tcp   open  ssh
3443/tcp open  SecureBank HTTPS
```

The SecureBank HTTPS service is intentionally exposed.

SSH, however, is a management service and does not need to be reachable from an attacker VM.

This lab therefore asks:

> Can the SecureBank application remain reachable while management access through SSH is blocked from the attacker network?

The experiment uses UFW on the Ubuntu target and verifies the resulting behavior externally from Kali Linux.

---

## Lab Summary

**Objective:** Restrict SSH access from the attacker network while preserving SecureBank HTTPS access.

**Attacker:**

```text
Kali Linux
192.168.56.10
```

**Target:**

```text
Ubuntu Server
192.168.56.20
securebank.lab
```

**Lab interface on Ubuntu:**

```text
enp0s8
192.168.56.20/24
```

**Technologies:**

- Kali Linux
- Ubuntu Server
- VirtualBox
- UFW
- OpenSSH
- Nmap
- curl
- systemd
- Linux sockets

---

## Lab Architecture

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
                                  ├── 22/tcp   SSH
                                  │
                                  └── 3443/tcp SecureBank HTTPS
```

The goal is to keep:

```text
3443/tcp
```

reachable while preventing Kali from reaching:

```text
22/tcp
```

---

## Security Question

The main question for the experiment was:

> Should a host on the attacker-facing lab network be able to reach both the public application and the target's management service?

SecureBank HTTPS represents the intended application surface.

SSH represents the management plane.

The desired model is:

```text
Attacker network
      │
      ├── SecureBank HTTPS :3443 → allowed
      │
      └── SSH :22                → blocked
```

---

## 1. Baseline Enumeration

Before configuring a firewall, the target was scanned from Kali:

```bash
nmap -p 22,3443 192.168.56.20
```

Result:

```text
PORT     STATE SERVICE
22/tcp   open  ssh
3443/tcp open  ov-nnm-websrv
```

Both services were remotely reachable.

### Baseline State

```text
22/tcp   open
3443/tcp open
```

This provided the before-state against which the firewall configuration could be compared.

---

## 2. Identifying the Target Interfaces

The Ubuntu network configuration was inspected using:

```bash
ip addr
```

Relevant interfaces were:

```text
enp0s3
10.0.2.15/24
```

and:

```text
enp0s8
192.168.56.20/24
```

The interfaces serve different purposes.

### `enp0s3`

```text
10.0.2.15/24
```

This is the VirtualBox NAT interface used for Internet access.

### `enp0s8`

```text
192.168.56.20/24
```

This is the isolated security-lab interface connecting the Ubuntu target to the Kali attacker VM.

The firewall rules were therefore scoped specifically to:

```text
enp0s8
```

rather than unnecessarily affecting unrelated traffic.

---

## 3. Checking the Existing Firewall State

UFW status was checked:

```bash
sudo ufw status verbose
```

Initial result:

```text
Status: inactive
```

This confirmed that the baseline Nmap result was not being affected by UFW filtering.

---

## 4. Configuring the Default Firewall Policy

Incoming traffic was denied by default:

```bash
sudo ufw default deny incoming
```

Outgoing traffic remained allowed:

```bash
sudo ufw default allow outgoing
```

Conceptually:

```text
Unsolicited incoming traffic
          │
          ▼
        DENY
```

while:

```text
Host-initiated outgoing traffic
          │
          ▼
        ALLOW
```

Explicit rules could then define which inbound services should remain reachable.

---

## 5. Allowing SecureBank HTTPS

SecureBank HTTPS must remain reachable from the lab network.

An interface-specific allow rule was created:

```bash
sudo ufw allow in on enp0s8 to any port 3443 proto tcp
```

This permits TCP connections arriving through the isolated lab interface and targeting port `3443`.

Conceptually:

```text
Kali
 │
 │ TCP/3443
 ▼
enp0s8
 │
 ▼
ALLOW
 │
 ▼
SecureBank HTTPS
```

---

## 6. Blocking SSH from the Attacker Network

SSH access from the isolated attacker-facing interface was denied.

The rule also enabled logging:

```bash
sudo ufw deny in on enp0s8 log proto tcp to any port 22
```

This creates two useful behaviors:

```text
prevent
+
observe
```

Traffic matching the rule is blocked while also producing firewall telemetry.

Conceptually:

```text
Kali
 │
 │ TCP/22
 ▼
enp0s8
 │
 ▼
DENY + LOG
 │
 X
SSH
```

---

## 7. Enabling UFW

After the rules were prepared, UFW was enabled:

```bash
sudo ufw enable
```

Because SSH was currently being used to administer the Ubuntu VM, the VirtualBox console was kept available as a recovery path before enabling the firewall.

This is important when modifying firewall rules remotely.

A firewall misconfiguration can otherwise lock the administrator out of the system being configured.

---

## 8. Resulting Firewall Policy

The effective security model was:

```text
Default incoming: deny
Default outgoing: allow
```

with explicit rules on `enp0s8`:

```text
TCP/3443 → ALLOW
TCP/22   → DENY + LOG
```

The public application remained intentionally exposed while the management service was removed from the attacker-accessible surface.

---

## 9. Verifying the Result with Nmap

The same scan was repeated from Kali:

```bash
nmap -p 22,3443 192.168.56.20
```

Result:

```text
PORT     STATE    SERVICE
22/tcp   filtered ssh
3443/tcp open     ov-nnm-websrv
```

The state changed from:

```text
22/tcp   open
3443/tcp open
```

to:

```text
22/tcp   filtered
3443/tcp open
```

This was the desired result.

---

## 10. Understanding Nmap Port States

The experiment demonstrates an important distinction between common Nmap port states.

### Open

```text
open
```

A service is reachable and accepting connections.

Example:

```text
3443/tcp open
```

### Closed

```text
closed
```

The target responds, but no application is listening on that port.

### Filtered

```text
filtered
```

A firewall or filtering mechanism prevents Nmap from determining normal service reachability.

After UFW was enabled:

```text
22/tcp filtered
```

indicated that network traffic was being blocked rather than the SSH service simply disappearing.

---

## 11. Verifying SecureBank Still Works

The application was tested directly from Kali:

```bash
curl -k -I https://securebank.lab:3443
```

Result:

```text
HTTP/1.1 200 OK
Server: nginx
```

The application remained available after the firewall change.

This proves that the attack surface was reduced without breaking the intended public service.

---

## 12. Testing SSH from Kali

A direct SSH connection was attempted:

```bash
ssh nina@192.168.56.20
```

The client appeared to hang because the packets were being filtered rather than actively rejected.

A shorter test can be performed using:

```bash
ssh -o ConnectTimeout=5 nina@192.168.56.20
```

The connection times out after the configured interval.

This behavior is consistent with the Nmap result:

```text
22/tcp filtered
```

---

## 13. Verifying SSH Was Not Stopped

It was important to distinguish between:

```text
service disabled
```

and:

```text
network access denied
```

The SSH service state was checked on Ubuntu:

```bash
sudo systemctl status ssh --no-pager
```

Result:

```text
Active: active (running)
```

SSH was therefore still operational.

---

## 14. Inspecting the Listening Socket

The target was also checked for a listening TCP socket:

```bash
ss -ltnp | grep :22
```

The system showed SSH listening on:

```text
0.0.0.0:22
[::]:22
```

This means SSH remained bound and available locally at the operating-system level.

However, Kali could no longer reach it through the lab interface.

This proves:

```text
service state:
running
```

while:

```text
network reachability:
blocked
```

---

## 15. Firewall Logging

The SSH deny rule was configured with:

```bash
sudo ufw deny in on enp0s8 log proto tcp to any port 22
```

A new SSH connection attempt was generated from Kali.

The resulting firewall log showed the blocked traffic.

Relevant fields included values equivalent to:

```text
SRC=192.168.56.10
DST=192.168.56.20
DPT=22
PROTO=TCP
```

These fields identify:

```text
SRC
source IP address

DST
destination IP address

DPT
destination port

PROTO
network protocol
```

The event therefore showed that:

```text
192.168.56.10
```

attempted to establish a TCP connection to:

```text
192.168.56.20:22
```

and the firewall blocked it.

---

## 16. Prevention and Visibility

The firewall now provides two security benefits.

### Prevention

Kali cannot directly connect to SSH.

### Visibility

Attempts to access the blocked management service can be recorded.

This creates a useful defensive pattern:

```text
attack attempt
      ↓
firewall
      ↓
blocked
      ↓
log event
      ↓
future detection / alert
```

This telemetry could later be forwarded into a SIEM such as Wazuh.

---

## Before and After Comparison

### Before UFW

```text
22/tcp   open
3443/tcp open
```

The attacker VM could reach both the public application and SSH management service.

### After UFW

```text
22/tcp   filtered
3443/tcp open
```

The application remained reachable while SSH was no longer accessible from Kali.

### Local SSH State

```text
ssh.service:
active

TCP/22:
listening

Kali access:
blocked
```

The network control therefore changed access rather than disabling the service itself.

---

## Security Observation — Management Plane Exposure

SSH is a management service.

Before firewalling, it was directly reachable from the same network as the attacker VM.

Even when SSH itself is securely configured, unnecessary network exposure increases the available attack surface.

Possible risks include:

- credential attacks
- password spraying
- brute-force attempts
- account enumeration
- version fingerprinting
- exploitation of future SSH vulnerabilities
- unnecessary management-plane reconnaissance

A useful defense-in-depth principle is therefore:

> Management interfaces should only be reachable from networks or systems that actually require administrative access.

---

## Public Application Plane vs Management Plane

The experiment created a clearer separation between two types of service.

### Public Application Plane

```text
SecureBank HTTPS
TCP/3443
```

This service is intentionally reachable.

### Management Plane

```text
SSH
TCP/22
```

This service is intended for administration rather than application users.

After the firewall configuration:

```text
Attacker VM
    │
    ├── 3443 → SecureBank → allowed
    │
    └── 22   → SSH        → blocked
```

---

## Host Firewall vs Full Network Segmentation

The Kali and Ubuntu systems remain members of the same subnet:

```text
192.168.56.0/24
```

Therefore, this experiment does not create full network segmentation using separate VLANs or routed security zones.

Instead, the host itself enforces which services are reachable.

A more precise description is:

> Host firewall enforcement and service segmentation.

Full network segmentation would typically involve concepts such as:

```text
different subnets
+
VLANs
+
routing boundaries
+
firewall rules between security zones
```

This lab establishes the underlying access-control concept without yet introducing that additional network architecture.

---

## Attack Surface Comparison

### Before

```text
Kali attacker
     │
     ├── TCP/22
     │      │
     │      ▼
     │     SSH
     │
     └── TCP/3443
            │
            ▼
        SecureBank
```

### After

```text
Kali attacker
     │
     ├── TCP/22 ───── X
     │
     └── TCP/3443
            │
            ▼
        SecureBank
```

The externally usable attack surface was reduced while application functionality remained intact.

---

## Security Engineering Workflow

This lab followed the portfolio's recurring workflow:

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

Applied specifically to this experiment:

```text
22 + 3443 reachable
        ↓
configure UFW
        ↓
allow 3443
deny + log 22
        ↓
rescan from Kali
        ↓
22 filtered
3443 open
        ↓
test SecureBank
        ↓
HTTP 200 OK
        ↓
check SSH locally
        ↓
service still running
        ↓
inspect firewall event
        ↓
blocked Kali connection logged
```

---

## Key Takeaways

Through this lab I practiced:

- establishing a network-exposure baseline
- identifying Linux network interfaces
- distinguishing NAT and isolated lab interfaces
- configuring UFW
- applying default-deny inbound policy
- writing interface-specific firewall rules
- explicitly allowing an application service
- blocking a management service
- enabling per-rule logging
- verifying firewall behavior using Nmap
- understanding `open`, `closed`, and `filtered` states
- testing blocked services using SSH
- verifying that SecureBank remained functional
- inspecting systemd service state
- inspecting TCP listening sockets
- distinguishing service availability from network reachability
- correlating firewall logs with an attacker IP address
- reducing attack surface without breaking required functionality
- distinguishing host firewalling from full network segmentation

---

## Lessons Learned

A service can be running without being remotely reachable:

```text
service listening
≠
service accessible
```

A firewall can change network behavior without changing application state:

```text
firewall filtering
≠
service shutdown
```

Reducing exposure is often preferable to relying only on the security of the exposed service itself:

```text
fewer reachable services
=
smaller attack surface
```

Preventive controls become more useful when they also produce security telemetry:

```text
block
+
log
=
prevention + visibility
```

---

## Future Work

Possible extensions include:

- allowing SSH only from a dedicated management host
- creating a separate management subnet
- comparing `DROP` and `REJECT` behavior
- inspecting filtered traffic with Wireshark
- forwarding UFW logs into Wazuh
- creating a detection rule for repeated blocked SSH attempts
- creating separate application and management security zones
- testing firewall behavior against Docker-published services

---

## Conclusion

This lab demonstrated how a host-based firewall can reduce the externally reachable attack surface of a system without disabling required services.

Before UFW was enabled, the Kali attacker VM could reach both:

```text
SSH :22
SecureBank HTTPS :3443
```

After applying an interface-specific firewall policy:

```text
22/tcp   filtered
3443/tcp open
```

SecureBank remained fully reachable while SSH was inaccessible from the attacker network.

The SSH daemon itself remained active and continued listening locally, proving that the change resulted from network access control rather than service shutdown.

The blocked connection was also logged, providing defensive visibility into attempted access.

The experiment demonstrates an important security principle:

> A service should not be reachable merely because it is running.

Network access should reflect the service's purpose and the trust level of the connecting network.