# John the Ripper Lab

## 🎯 Objective  

This lab aims to provide hands-on experience with John the Ripper on Kali Linux, covering a range of common password hash types and real-world scenarios such as cracking password-protected archives and encrypted SSH keys. You will learn how to:

- Prepare hash files for different algorithms (MD5, SHA256, NTLM).
- Use John the Ripper’s various modes and formats to crack these hashes.
- Extract hashes from password-protected ZIP and RAR archives as well as encrypted SSH private keys.
- Understand the importance of selecting correct cracking formats and wordlists.
- Interpret John the Ripper output and manage pot files to track cracked hashes.

This foundational knowledge is essential for penetration testing, digital forensics, and cybersecurity investigations.

## 🛠️ Lab Setup

- **OS:** Kali Linux (running on VirtualBox)
- **Tool:** John the Ripper (preinstalled)
- **Wordlist:** `/usr/share/wordlists/rockyou.txt`


## 🔍 Steps and Observations  

### Step 1
- Create separate files for different hash types to practice cracking(see screenshot).

### Step 2: Crack MD5 Hashes
```bash
john --format=raw-md5 --wordlist=/usr/share/wordlists/rockyou.txt md5_hashes.txt
```

### Step 3: Crack SHA256 Hashes
```bash
john --format=raw-sha256 --wordlist=/usr/share/wordlists/rockyou.txt sha256_hashes.txt
```
### Step 4: Crack NTLM Hashes
```bash
john --format=nt --wordlist=/usr/share/wordlists/rockyou.txt ntlm_hashes.txt
```

### Step 5: Cracking Password-Protected Zip Files

1. Extract the hash from the zip file using `zip2john`:

```bash
zip2john protected.zip > zip_hash.txt
```

Crack the extracted hash with John:

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt zip_hash.txt
```

### Step 6: Cracking Password-Protected RAR Archives
1. Extract the hash from the rar file using `rar2john`:

```bash
rar2john protected.rar > rar_hash.txt
```
Crack the extracted hash with John:

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt rar_hash.txt
```

### Step 7: Cracking SSH Keys
1. Extract the hash from the SSH private key using ssh2john:

```bash
ssh2john id_rsa > ssh_hash.txt
```
Crack the extracted hash with John:

```bash
john --wordlist=/usr/share/wordlists/rockyou.txt ssh_hash.txt
```

## 📝 Key Takeaways
- Keeping hashes separated by type simplifies cracking.
- Using the correct --format option is crucial.
- Wordlists and rules improve cracking success.

## 📂 Files

- Crack zip file: [`screenshots/crack-zip-file.png`](screenshots/crack-zip-file.png)  
- Cracking process: [`screenshots/cracking.png`](screenshots/cracking.png)  
- Hashes create: [`screenshots/hashes-create.png`](screenshots/hashes-create.png)  
- Verify zip content: [`screenshots/verify-zip-content.png`](screenshots/verify-zip-content.png)  
