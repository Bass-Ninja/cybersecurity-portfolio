# Lab 02 — Docker Network Exposure

## Overview

This lab investigates how Docker port publishing affects the network exposure of services in the SecureBank environment.

The experiment compares three different ways of exposing the same application service:

1. Binding a container port only to the host loopback interface
2. Publishing a container port on all host interfaces
3. Not publishing the container port to the host at all

The lab also examines whether backend services such as PostgreSQL need to be published to the host for the application to function.

The goal is to distinguish between **container-internal reachability** and **host/network exposure**, and to verify how Docker configuration influences the externally reachable attack surface.

## Lab Summary

**Objective:** Determine how Docker port mappings affect service reachability.

**Key observation:** A container can remain reachable to other containers on the same Docker network without publishing its port to the host.

**Security implication:** Publishing unnecessary ports increases the host's reachable attack surface.

**Remediation:** Remove unnecessary host port mappings and expose only services that require external access.

**Technologies:** Docker, Docker Compose, PowerShell, TCP/IP, SecureBank

---

## Lab Environment

The SecureBank environment consisted of four containers:

```text
securebank-web
securebank-api
securebank-keycloak
securebank-postgres
```

Inspection of the Docker network showed the containers connected to the same bridge network:

```text
securebank-keycloak   172.18.0.2/16
securebank-postgres   172.18.0.3/16
securebank-api        172.18.0.4/16
securebank-web        172.18.0.5/16
```

The host machine used the LAN address:

```text
192.168.1.149
```

The experiment was performed from the Windows host before introducing a separate Kali Linux VM.

---

## Docker Port Mapping

Docker Compose allows a host IP and host port to be mapped to a container port.

For example:

```yaml
ports:
  - "127.0.0.1:8080:8080"
```

binds the host port only to the loopback interface.

By comparison:

```yaml
ports:
  - "8080:8080"
```

publishes the service without explicitly restricting the host interface.

Docker reported this as:

```text
0.0.0.0:8080->8080/tcp
[::]:8080->8080/tcp
```

A service can also run without any host port mapping:

```yaml
# no ports section
```

In this case, containers on the same Docker network can still communicate directly using their container/service names.

---

# Test 1 — Loopback-Only Binding

## Configuration

The SecureBank API initially used:

```yaml
ports:
  - "127.0.0.1:8080:8080"
```

Docker reported:

```text
127.0.0.1:8080->8080/tcp
```

The service was reachable locally through:

```text
http://localhost:8080
```

The same service was then tested using the host's LAN address:

```powershell
curl.exe http://192.168.1.149:8080/health/ready
```

## Result

The connection failed:

```text
curl: (7) Failed to connect to 192.168.1.149:8080
```

The API HTTPS port was also loopback-bound:

```text
127.0.0.1:8443->8443/tcp
```

and similarly could not be reached through the LAN interface.

## Observation

Binding the published port to `127.0.0.1` allowed host-local access while preventing the service from being reached using the host's LAN address.

---

# Test 2 — Publishing the API on All Host Interfaces

## Configuration

The API mapping was temporarily changed from:

```yaml
- "127.0.0.1:8080:8080"
```

to:

```yaml
- "8080:8080"
```

After recreating the container, Docker reported:

```text
0.0.0.0:8080->8080/tcp
[::]:8080->8080/tcp
```

The API was then tested through the host's LAN address:

```powershell
curl.exe http://192.168.1.149:8080/health/ready
```

## Result

The request succeeded:

```text
Healthy
```

## Observation

Changing only the Docker host binding made the same API service reachable through the host's non-loopback network interface.

This demonstrated that Docker port publishing directly affects the externally reachable host attack surface.

---

# Test 3 — No Published API HTTP Port

## Configuration

The API's HTTP port mapping was removed entirely.

The container continued listening internally on port `8080`, but no host port was mapped to it.

## Host Verification

The API was tested from the Windows host:

```powershell
curl.exe http://localhost:8080/health/ready
```

Result:

```text
Connection failed
```

The LAN address was also tested:

```powershell
curl.exe http://192.168.1.149:8080/health/ready
```

Result:

```text
Connection failed
```

The service was therefore no longer reachable through either host interface.

---

## Internal Docker Network Verification

Removing the host port did not stop the API container from communicating with other containers.

From the SecureBank web container:

```powershell
docker exec securebank-web wget -qO- http://securebank-api:8080/health/ready
```

The response was:

```text
Healthy
```

This confirmed that the API remained reachable over the internal Docker network despite having no published HTTP host port.

The communication path was:

```text
securebank-web
      │
      │ Docker bridge network
      ▼
securebank-api:8080
```

No Windows host port was required.

---

## Key Concept — Internal Reachability vs Host Exposure

The experiment demonstrated that these are separate concepts:

```text
Service running inside container
            │
            ▼
Reachable from Docker network
            │
            X
No requirement for host exposure
```

A service does not need to be published to the host for containers on the same Docker network to communicate with it.

Docker's internal DNS also allows containers to communicate using service or container names instead of relying on dynamically assigned container IP addresses.

---

# PostgreSQL Exposure Analysis

The PostgreSQL container initially published its database port to the host:

```yaml
ports:
  - "127.0.0.1:15432:5432"
```

This did not expose PostgreSQL to the LAN, because the port was bound to loopback, but it still created a directly reachable database port on the Windows host.

The SecureBank API itself connects to PostgreSQL using the internal Docker address:

```text
Host=postgres
Port=5432
```

This raised the question:

> Does PostgreSQL need a host-published port for SecureBank to operate?

---

## Removing the PostgreSQL Host Mapping

The PostgreSQL `ports` configuration was removed.

Docker then reported:

```text
5432/tcp
```

rather than:

```text
127.0.0.1:15432->5432/tcp
```

This indicated that PostgreSQL remained available inside the Docker environment but no longer had a port published to the host.

---

## Host Verification

The previous host port was tested using:

```powershell
Test-NetConnection localhost -Port 15432
```

The result was:

```text
TcpTestSucceeded : False
```

Both IPv4 and IPv6 loopback connection attempts failed.

This confirmed that PostgreSQL was no longer directly reachable from the Windows host.

---

## Application Verification

SecureBank was then tested through the normal web application.

The application was still able to:

- authenticate a user
- load the application
- retrieve database-backed data

This demonstrated that the API could continue communicating with PostgreSQL using:

```text
postgres:5432
```

over the Docker network.

The host mapping was unnecessary for normal application operation.

---

# Attack Surface Reduction

Before hardening:

```text
Windows Host
    │
    ├── SecureBank services
    │
    └── localhost:15432
             │
             ▼
         PostgreSQL
```

After hardening:

```text
Windows / External Network
            │
            ▼
     Public Application
            │
        Docker network
         ┌───────┐
         │       │
         ▼       ▼
       API    Keycloak
         │
         ▼
     PostgreSQL
```

PostgreSQL remains available to the API but no longer exposes an unnecessary host port.

The API's internal HTTP listener similarly remains available to other containers without being published directly to the host.

---

# Final SecureBank Exposure Model

After the experiment, the Compose configuration was adjusted so that:

| Service | Port | Exposure |
| --- | ---: | --- |
| Web HTTPS | `3443` | All host interfaces / intended public entry point |
| Web HTTP | `3000` | Loopback only |
| API HTTPS | `8443` | Loopback only |
| API HTTP | `8080` | Docker network only |
| Keycloak | `8081` | Loopback only |
| PostgreSQL | `5432` | Docker network only |

The HTTPS frontend is intentionally externally reachable because it represents the application's public entry point.

Backend services that do not require direct external access remain restricted to the Docker network or host loopback interface.

---

## Security Implications

Publishing a Docker port creates an additional path through which a service can potentially be reached.

The experiment demonstrated that:

- Binding to `127.0.0.1` restricts host publishing to the loopback interface.
- Publishing without a specific host IP can make the service reachable through non-loopback interfaces.
- Removing the mapping prevents direct host access while preserving container-to-container communication.
- Internal backend services do not necessarily need host-published ports.
- Reducing unnecessary port exposure reduces the externally reachable attack surface.

Port exposure is only one layer of network security. Host firewalls, application authentication, network segmentation, and other controls can further restrict reachability.

---

## Hardened Configuration

The SecureBank environment was left with the API HTTP listener and PostgreSQL available only over the internal Docker network.

The application's HTTPS entry point remains externally reachable to support normal application access and future testing from an isolated Kali Linux VM.

This creates a more realistic security boundary:

```text
Kali / Client
     │
     │ HTTPS
     ▼
SecureBank public entry point
     │
     ▼
Docker internal services
     ├── API
     ├── Keycloak
     └── PostgreSQL
```

Future labs will test this boundary from a separate attacker VM rather than assuming the configuration provides the intended isolation.

---

## Key Takeaways

Through this lab I practiced:

- Inspecting Docker port mappings
- Distinguishing loopback from all-interface bindings
- Testing service reachability through different host interfaces
- Understanding Docker bridge networking
- Inspecting container IP addresses and network membership
- Using Docker's internal DNS for container-to-container communication
- Distinguishing internal service reachability from host exposure
- Removing unnecessary host port mappings
- Verifying that application functionality remains intact after hardening
- Reducing the exposed application attack surface

---

## Conclusion

This lab demonstrated how Docker port publishing affects the network exposure of application services.

The same SecureBank API was tested in three configurations: loopback-only publishing, publishing on all host interfaces, and no host publishing.

When bound to loopback, the API was available locally but could not be reached through the host LAN interface. Publishing the same port without an explicit host address made the API reachable through the LAN address.

Removing the host mapping prevented direct host access entirely while preserving communication between containers on the internal Docker network.

The same principle was then applied to PostgreSQL. Removing its host port prevented direct database access from the Windows host while SecureBank continued operating normally through Docker-internal communication.

The final configuration therefore exposes the application's intended public entry point while keeping unnecessary backend services internal, reducing attack surface without breaking application functionality.