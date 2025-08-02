# Gobuster Directory Brute-Forcing Walkthrough

## Objective
Use **Gobuster** to discover hidden directories and pages on FakeBank’s website by brute forcing common directory names.

---

## Tools Used
- **Gobuster** — CLI directory/file brute forcing tool  
- **Wordlist** — `/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt` (comes with Kali Linux)  

---

## Steps

### 1. Understand the target
- Target URL: `http://fakebank.com` (replace with actual target)  
- Goal: Find hidden or sensitive directories not linked on the homepage  

### 2. Prepare your environment
- Open a terminal on Kali Linux or your preferred pentesting environment  
- Ensure Gobuster is installed:  
  ```bash
  gobuster --help
  ```
  
Locate a suitable wordlist (using DirBuster medium list in this example):
```
ls /usr/share/wordlists/dirbuster/
```
### 3. Run Gobuster
Run the following command to start brute forcing directories:

```
gobuster dir -u http://fakebank.com -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
```

Options explained:

dir — directory brute force mode

-u — target URL

-w — wordlist path

### 4. Analyze results
Gobuster will output lines like:

```
/admin (Status: 200)
/backup (Status: 301)
/secret (Status: 403)
```
200 — directory/page exists and accessible

301 — redirect, likely an existing page with redirect

403 — forbidden access, might be interesting for further investigation

### 5. Further actions
Manually visit found directories in a browser

Check if you can enumerate files or perform other attacks (like uploading files or SQL injection)

Document any sensitive info or vulnerabilities discovered
