# Automated Web Security Scanning and False-Positive Validation

## Objective

Evaluate an automated web security scanner against a local lab application, validate reported findings manually, identify false positives, and improve the target configuration based on the results.

## Lab Environment

- Attacker: Kali Linux
- Target: Ubuntu Server VM
- Application: SecureBank
- Stack:
  - .NET API
  - Nginx frontend / reverse proxy
  - Keycloak
  - Docker Compose
- Target hostname: `securebank.lab`
- HTTPS port: `3443`
- Scanner: `fya 0.6.0`

Detected external tools included:

- Nikto
- Nmap
- sqlmap
- SSLyze

## Initial Scanning

Scanning was performed progressively using:

```bash
fya scan https://securebank.lab:3443 --profile passive
```

```bash
fya scan https://securebank.lab:3443 --profile safe
```

```bash
fya scan https://securebank.lab:3443 --profile aggressive
```

The passive scan mainly identified TLS and HTTP hardening issues.

The safe and aggressive profiles introduced active probing and external-tool integration.

## Initial Aggressive Scan

The initial aggressive scan generated a very large number of findings.

A major source was Nikto, which reported many apparently exposed backup and certificate files such as:

```text
/site.tar
/site.war
/backup.pem
/database.jks
/archive.tgz
```

The scan produced 163 findings from external tools alone.

Rather than assuming these resources actually existed, the findings were manually validated.

## Manual Validation

A supposedly sensitive route was requested directly:

```bash
curl -k -i https://securebank.lab:3443/admin
```

The response was:

```text
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 649
```

However, the body was the normal SecureBank SPA shell:

```html
<title>SecureBank</title>
<div id="app">
```

The same behavior was observed for:

```text
/actuator
```

and an intentionally nonexistent path:

```text
/this-definitely-does-not-exist-12345
```

All returned the same HTTP 200 response and SPA HTML.

This confirmed that many scanner findings were false positives.

## Root Cause

The Nginx configuration used SPA fallback routing:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

Unknown paths were therefore served `index.html` with HTTP 200 instead of returning HTTP 404.

Security scanners interpreted these successful responses as evidence that requested files or sensitive endpoints existed.

This behavior is effectively a soft-404 from the scanner's perspective.

## Nginx Improvement

Instead of hardcoding individual dangerous file extensions, file-like requests were required to reference an actual file:

```nginx
location ~ \.[^/]+$ {
    try_files $uri =404;
}

location / {
    try_files $uri $uri/ /index.html;
}
```

This preserved normal SPA routing while ensuring nonexistent file-like paths returned HTTP 404.

## Scanner Result After Routing Fix

After rebuilding the application and running the aggressive scan again, external-tool findings dropped from:

```text
163
```

to:

```text
7
```

This confirmed that most of the original Nikto findings were caused by SPA fallback behavior rather than exposed files.

## Security Header Regression

After the Nginx routing change, a new aggressive scan reported missing headers including:

```text
Content-Security-Policy
X-Frame-Options
X-Content-Type-Options
Referrer-Policy
Permissions-Policy
```

Manual verification confirmed the headers were genuinely absent:

```bash
curl -k -I https://securebank.lab:3443/
```

The cause was Nginx location matching.

The security headers had originally been configured inside:

```nginx
location / {
    add_header ...
}
```

After `/index.html` was internally selected, it matched the new regex location:

```nginx
location ~ \.[^/]+$
```

and the headers configured in `location /` were no longer applied.

## Security Header Fix

The security headers were moved to the HTTPS `server` block so they would be inherited by the relevant locations:

```nginx
server {
    listen 443 ssl;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Permissions-Policy "camera=(), geolocation=(), microphone=()" always;

    add_header Content-Security-Policy \
        "default-src 'self'; \
         base-uri 'none'; \
         connect-src 'self'; \
         font-src 'self'; \
         form-action 'self'; \
         frame-ancestors 'none'; \
         img-src 'self' data:; \
         object-src 'none'; \
         script-src 'self'; \
         style-src 'self'" always;

    location ~ \.[^/]+$ {
        try_files $uri =404;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

The headers were verified again with:

```bash
curl -k -I https://securebank.lab:3443/
```

## Final Aggressive Scan

The final scan was performed using the hostname matching the TLS certificate:

```bash
fya scan https://securebank.lab:3443 --profile aggressive
```

The final result contained:

```text
1 high
14 medium
1 low
2 informational
```

with only four findings from external tools.

Most remaining medium findings involving routes such as:

```text
/admin
/dashboard
/administrator
/actuator
/metrics
```

were still caused by SPA fallback behavior for extensionless routes and were manually treated as false positives.

The remaining genuine or expected findings included:

- self-signed / untrusted development TLS certificate
- missing HSTS
- missing or weak Cross-Origin-Opener-Policy
- missing Cross-Origin-Resource-Policy
- missing `security.txt`

## Key Takeaways

Automated scanner output should not be accepted without validation.

HTTP 200 does not necessarily mean that a requested resource exists.

SPA fallback routing can cause large numbers of false positives in scanners that rely heavily on response status and content size.

Manual verification with tools such as `curl` is useful for distinguishing genuine findings from scanner noise.

Nginx location matching and directive inheritance can also introduce unexpected security configuration regressions.

The final result was less about making the scanner report zero findings and more about understanding which findings represented genuine application behavior and which were artifacts of automated detection.