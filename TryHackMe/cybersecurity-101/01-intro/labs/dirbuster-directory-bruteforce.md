# Dirbuster Directory Brute-Forcing

## 🎯 Objective  
Use **Dirbuster** to discover hidden directories and pages on a target web server by brute forcing common directory names.

---

## 🛠️ Lab Setup  
- Environment: Kali Linux VM (or any Linux with Dirbuster installed)  
- Tools used: Dirbuster (GUI tool for directory brute forcing)  
- Network: Localhost (127.0.0.1) web server running Apache2  
- Wordlist: `/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt` (default Kali wordlist)  

Setup steps:  
1. Ensure Apache2 is installed and running on your Kali VM:  
```bash
  sudo apt update
  sudo apt install apache2
  sudo systemctl start apache2
  sudo systemctl enable apache2
```
2. Create test directories under /var/www/html:

```bash
  sudo mkdir /var/www/html/admin
  sudo mkdir /var/www/html/backup
  sudo mkdir /var/www/html/secret
```
3. Add a file:

```bash
echo "Top secret stuff" | sudo tee /var/www/html/secret/index.html
```

4. Confirm you can access the default web server at http://127.0.0.1 in your browser.

## 🔍 Steps and Observations
Open Dirbuster:

```bash
dirbuster
```

- Set Target URL to: http://127.0.0.1
- Set wordlist path to:
`/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt`
- Set file extension to .html
- Start the scan and monitor output for discovered directories.
- Observe the HTTP status codes for each found directory:

```bash
200: Directory exists and accessible
301: Redirect (likely a valid page)
403: Forbidden (might require further investigation)
```

## 📊 Analysis and Results
- Dirbuster discovered directories such as /admin, /backup, and /secret.
- Status codes helped identify which directories are accessible or restricted.
- These findings can reveal hidden or sensitive resources on a web server.

## 📝 Key Takeaways
- Dirbuster is a powerful GUI tool for directory brute forcing.
- Running a local web server allows safe practice without network issues.
- Understanding HTTP status codes is essential for analyzing scan results.

## 📂 Files
Dirbuster usage: [`screenshots/dirbuster-brute-force.png`](screenshots/dirbuster-brute-force.png)  
Secret page: [`screenshots/secret-index-page.png`](screenshots/secret-index-page.png) 