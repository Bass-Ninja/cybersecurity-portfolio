# 🔐 SSH Lab Setup: Kali → Ubuntu Server

## 🛠️ Environment

- **Host OS**: Windows 11
- **Virtualization**: VirtualBox
- **VMs**:
  - **Kali Linux** (Attacker)
  - **Ubuntu Server** (Target)

## 🌐 Network Configuration

### Adapters Used

- **Kali Linux**:  
  - Adapter 1: `Host-only Adapter`
  - IP (example): `192.168.56.101`

- **Ubuntu Server**:
  - Adapter 1: `Host-only Adapter`
  - Adapter 2: *Temporarily used* `NAT` to install `openssh-server`
  - Final IP (example): `192.168.56.103`

**Notes:**
- NAT adapter was temporarily used for internet access to install packages.
- Host-only ensures isolated internal communication between Kali and Ubuntu.

## ⚙️ Installation & Configuration (on Ubuntu Server)

```bash
sudo apt update
sudo apt install openssh-server
```

## 🖧 Verifying Network & Connectivity

1. On both machines:

```bash
ip a
```

- Check that both Kali and Ubuntu are on the same subnet (192.168.56.x).

2. From Kali:

```bash
ping 192.168.56.103   # Ubuntu’s IP
ssh ubuntu@192.168.56.103
```

## 📂 Files  
- SSH Login: [`screenshots/ssh-login.png`](screenshots/ssh-login.png)  
