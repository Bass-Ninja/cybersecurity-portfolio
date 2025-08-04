# Windows Fundamentals

## 🎯 Objective  
Explore core features of the Windows OS related to security: NTFS, UAC, Registry, System Tools.

## 🛠️ Environment  
- Host: Windows 11 Home  
- Tools used: File Explorer, PowerShell, Control Panel

## 🔍 Observations  
1. NTFS supports file permissions via the "Security" tab — useful for limiting access.  
2. UAC was set to “Notify me only when apps try to make changes.”  
3. The Registry contains all system configuration — I browsed `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft`.

## 📝 Key Takeaways  
- UAC is a key layer against privilege escalation.  
- NTFS is permission-based and supports encryption.  
- The Windows Registry is powerful but dangerous to modify.
