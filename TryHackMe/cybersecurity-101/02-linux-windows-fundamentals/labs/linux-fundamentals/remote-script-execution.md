# Bonus Task: Remote Script Execution with SCP and SSH

## 🎯 Objective  
Learn how to transfer a script from your Kali Linux machine to a remote Ubuntu server and execute it remotely using SSH.

## 🛠️ Lab Setup  
- Kali Linux VM (local machine)  
- Ubuntu Server VM (remote machine) with SSH enabled  
- Both machines connected on the same network (e.g., Host-only adapter)  

## 🔍 Steps and Observations  

1. **Create a Bash script on Kali:**  
    Write a simple shell script named `ascii_writer.sh` that outputs ASCII art into a file on the remote machine.

2. **Make the script executable:**  
    Run `chmod +x ascii_writer.sh` on Kali to ensure the script can be executed.

3. **Copy the script to Ubuntu using SCP:**  
    Use the `scp` command to securely copy the script file to the home directory of the Ubuntu user:
    ```bash
    scp ascii_writer.sh ubuntu@<Ubuntu_IP>>:/home/ubuntu/
    ```

4. **SSH into the Ubuntu server:**
    Connect to the Ubuntu server via SSH:

    ```bash
    ssh ubuntu@<Ubuntu-IP>
    ```

    Once logged in, execute the script:
    ```bash
    ./ascii_writer.sh
    ```
    
5. **Verify the output:**
    Check that the file ascii_art.txt was created in the Ubuntu user’s home directory and contains the ASCII art.
