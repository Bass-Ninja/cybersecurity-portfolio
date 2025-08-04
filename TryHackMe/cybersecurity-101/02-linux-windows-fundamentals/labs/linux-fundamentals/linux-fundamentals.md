# Linux Fundamentals

## 🎯 Objective  
Gain a foundational understanding of Linux command line, file system navigation, user management, and common utilities used in daily operations and security tasks.

## 🛠️ Lab Setup  
- **Environment:** VirtualBox with two VMs  
  - Kali Linux (attacker/analysis machine)  
  - Ubuntu Server (target machine for SSH and Linux fundamentals)  
- **Network:** Host-Only Adapter (shared internal VirtualBox network)  
- **Tools used:** SSH, terminal, basic Linux utilities  

## 🔍 Steps and Observations  

### Part 1: Essential Commands & Terminal Basics  
1. Navigate directories using `ls`, `cd`, `pwd`  
2. View file contents with `cat`, `less`  
3. Manage files with `touch`, `cp`, `mv`, `rm`  
4. Check and modify file permissions with `ls -l`, `chmod`, and `chown`  

### Part 2: File System Hierarchy  
2. Explore Linux file system hierarchy (`/home`, `/etc`, `/var`, `/usr`)  
3. Use `find` and `grep` to search for files and contents  
4. Compress and extract files using `tar`, `gzip`  

### Part 3: Common Utilities and Package Management  
1. View running processes using `ps aux` and `top`  
2. Kill processes with `kill` and `killall`  
3. Install software packages with `apt install <package>`  
4. Edit files using `nano` and `vim`  

## 📊 Analysis and Results  
Through this lab, I learned how to effectively navigate and manage a Linux system using command-line tools, understand file permissions crucial for security, remotely connect via SSH, and manage software and processes.

## 📝 Key Takeaways  
- Linux command line proficiency is essential for system administration and security tasks.  
- SSH provides secure remote access critical for managing servers.  
- Understanding the Linux file system layout helps in navigating and troubleshooting.  
- Package management and process control are fundamental skills.  

## 📂 Files  
- File create: [`screenshots/file-create.png`](screenshots/file-create.png)  
- Nano editor: [`screenshots/nano-editor.png`](screenshots/nano-editor.png)  
- Copy files: [`screenshots/copy-files.png`](screenshots/copy-files.png)  
- File permission change: [`screenshots/file-permission-change.png`](screenshots/file-permission-change.png)
- List user processes: [`screenshots/list-user-processes.png`](screenshots/list-user-processes.png)
