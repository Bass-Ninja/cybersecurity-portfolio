# Network Fundamentals

This room introduces the foundational concepts of networking, essential for both offensive and defensive cybersecurity.

---

## 🧠 Topics Covered

### Task 1 – What is Networking?
- Networking is the practice of connecting computers and other devices to share resources and data.
- Key components include **hosts**, **routers**, **switches**, and **protocols** that govern data exchange.

### Task 2 – What is the Internet?
- The Internet is a global network made up of interconnected smaller networks.
- It enables communication and data sharing using standardized protocols like **TCP/IP**.
- Important concepts:
  - **ISP (Internet Service Provider)**
  - **IP addresses (IPv4 and IPv6)**
  - **DNS (Domain Name System)**

### Task 3 – Identifying Devices on a Network
- Each device on a network has a unique **IP address** and **MAC address**.
- Common tools to identify devices:
  - `arp -a`
  - `ip a`
  - `ifconfig` (older)
  - Network scanning tools like **nmap**

### Task 4 – Ping (ICMP)
- **Ping** uses the **ICMP** protocol to test if a host is reachable.
- Sends echo request packets and waits for echo reply.
- Helpful for basic connectivity troubleshooting.

```bash
ping [IP_ADDRESS or HOSTNAME]
