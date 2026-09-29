# BOLA / IDOR Testing

## Objective

Test whether SecureBank correctly enforces object-level authorization when authenticated users modify client-controlled resource identifiers.

The goal was to answer two questions:

> Can one authenticated user initiate a transfer from another user's account by changing `sourceAccountId`?

and:

> Can one authenticated user delete another user's beneficiary by changing the beneficiary ID?

The tests were performed with Burp Suite against the isolated SecureBank lab environment.

---

## Lab Environment

### Attacker

```text
Kali Linux
192.168.56.10
```

### Target

```text
Ubuntu Server
192.168.56.20
securebank.lab
```

### Application

```text
https://securebank.lab:3443
```

### Technologies

- Burp Suite
- HTTP/HTTPS
- REST API
- Bearer JWT authentication
- ASP.NET Core
- Keycloak
- Nginx
- Docker

---

## Background

Broken Object Level Authorization, commonly referred to as BOLA or IDOR, occurs when an application accepts a client-controlled object identifier without verifying that the authenticated user is authorized to access or modify that object.

For example:

```http
GET /api/accounts/123
Authorization: Bearer <token>
```

If a user can replace:

```text
123
```

with:

```text
456
```

and access another user's account, the application has failed to enforce authorization at the object level.

Secure applications must enforce ownership or authorization on the server.

The client cannot be trusted to supply only identifiers that belong to the authenticated user.

---

# Test 1 — Transfer Source Account Ownership

## Security Question

> Can Nina initiate a transfer from an account belonging to another user by changing `sourceAccountId`?

---

## Baseline Request

A legitimate transfer request was captured in Burp Suite while authenticated as Nina.

```http
POST /api/transfers HTTP/1.1
Host: securebank.lab:3443
Authorization: Bearer <NINA_TOKEN>
Idempotency-Key: <UUID>
Content-Type: application/json
```

Example request body:

```json
{
  "sourceAccountId": "a80402f2-6f05-4912-b850-e6cac5b13665",
  "destinationAccountNumber": "SI560000000000000002",
  "amount": 5,
  "currency": "EUR"
}
```

The `sourceAccountId` belonged to Nina.

The request succeeded and returned a transfer identifier.

```http
HTTP/1.1 200 OK
Content-Type: application/json
```

```json
{
  "transferId": "<transfer-id>"
}
```

---

## Foreign Account

A second account belonging to another test user was identified:

```text
Account ID:
4cda625d-ed3a-4ffa-8120-43a536b96261

Account number:
SI560000000000000003

Currency:
EUR
```

The objective was to determine whether Nina could submit this account ID as the transfer source while remaining authenticated as Nina.

---

## Initial Replay and Idempotency Observation

The original transfer request was replayed in Burp Repeater with a different `sourceAccountId`, but the same `Idempotency-Key`.

The server returned the same `transferId` as the original request.

This showed that the request was being treated as an idempotent replay rather than being processed as a new transfer.

```text
same Idempotency-Key
+
different request body
=
same transferId
```

This result could therefore not be used to evaluate object-level authorization.

A fresh idempotency key was required for the actual BOLA test.

---

## BOLA Test

The request was repeated using:

```text
Authentication:
Nina's bearer token

sourceAccountId:
another user's account

Idempotency-Key:
new UUID
```

Only the object identifier and the idempotency key were changed.

The relevant request body became:

```json
{
  "sourceAccountId": "4cda625d-ed3a-4ffa-8120-43a536b96261",
  "destinationAccountNumber": "SI560000000000000002",
  "amount": 5,
  "currency": "EUR"
}
```

Nina remained the authenticated principal.

---

## Result

The server rejected the request:

```http
HTTP/1.1 403 Forbidden
Content-Type: application/json; charset=utf-8
```

Response:

```json
{
  "title": "Access forbidden.",
  "status": 403,
  "detail": "You are not allowed to transfer from this account.",
  "instance": "/api/transfers"
}
```

---

## Interpretation

The backend did not trust the supplied `sourceAccountId`.

It validated whether the authenticated user was permitted to transfer funds from the referenced account.

The foreign account existed, but Nina was explicitly denied access.

This indicates that server-side object ownership validation is enforced for transfer source accounts.

### Result

```text
BOLA / IDOR: NOT VULNERABLE
```

for this tested authorization boundary.

---

# Test 2 — Beneficiary Deletion Ownership

## Security Question

> Can Nina delete a beneficiary belonging to another user by replacing the beneficiary ID in the request?

---

## Test Setup

A beneficiary was created while authenticated as the second test user.

The beneficiary ID was:

```text
ebc7ecb9-2c4d-458a-8b4c-cb04bfdc331d
```

Nina was then authenticated separately.

A normal beneficiary deletion request was intercepted in Burp Suite.

The beneficiary identifier in the URL was replaced with the identifier belonging to the other user.

Conceptually:

```http
DELETE /api/beneficiaries/<NINA-BENEFICIARY-ID>
Authorization: Bearer <NINA_TOKEN>
```

was changed to:

```http
DELETE /api/beneficiaries/ebc7ecb9-2c4d-458a-8b4c-cb04bfdc331d
Authorization: Bearer <NINA_TOKEN>
```

The authentication context remained Nina's.

Only the object identifier was modified.

---

## Result

The application returned:

```http
HTTP/1.1 404 Not Found
Content-Type: application/json; charset=utf-8
```

Response:

```json
{
  "title": "Resource not found.",
  "status": 404,
  "detail": "The beneficiary was not found.",
  "instance": "/api/beneficiaries/ebc7ecb9-2c4d-458a-8b4c-cb04bfdc331d"
}
```

---

## Verification

After the failed deletion attempt, the beneficiary was checked again while authenticated as its legitimate owner.

The beneficiary still existed.

Therefore:

```text
Nina's request
→ foreign beneficiary ID
→ 404 Not Found
→ beneficiary remained intact
```

---

## Interpretation

The application prevented Nina from deleting another user's beneficiary.

Unlike the transfer test, which returned:

```text
403 Forbidden
```

the beneficiary endpoint returned:

```text
404 Not Found
```

This is a common authorization pattern.

Rather than confirming that the foreign object exists and explicitly denying access, the application behaves as though the object does not exist from the perspective of the unauthorized user.

This reduces information disclosure while still enforcing object ownership.

### Result

```text
BOLA / IDOR: NOT VULNERABLE
```

for this tested authorization boundary.

---

# Authorization Patterns Observed

The two endpoints used different but valid authorization responses.

## Transfer Endpoint

```text
foreign sourceAccountId
        ↓
ownership check
        ↓
403 Forbidden
```

The application explicitly tells the authenticated user that the operation is not permitted.

---

## Beneficiary Endpoint

```text
foreign beneficiaryId
        ↓
ownership-scoped lookup
        ↓
404 Not Found
```

The application does not reveal whether the foreign object exists.

Both approaches prevented unauthorized access.

---

# Idempotency Observation

An additional behavior was observed while testing transfers.

Replaying a request with the same:

```http
Idempotency-Key
```

returned the previously created:

```text
transferId
```

even after the request body was modified.

This prevented the repeated request from being treated as a new transfer.

This behavior was not the main subject of this lab, but it demonstrated why replay and idempotency controls must be considered when testing state-changing API endpoints.

A fresh idempotency key was therefore used for the final authorization test.

Replay resistance and idempotency behavior can be tested separately in a future lab.

---

# Findings Summary

| Test | Manipulation | Result | Authorization Outcome |
|---|---|---|---|
| Transfer source account | Replaced Nina's `sourceAccountId` with another user's account ID | `403 Forbidden` | Ownership enforced |
| Beneficiary deletion | Replaced Nina's beneficiary ID with another user's beneficiary ID | `404 Not Found` | Ownership enforced |
| Idempotency replay | Reused the same `Idempotency-Key` with a modified request | Original `transferId` returned | Request treated as replay |

No BOLA/IDOR vulnerability was confirmed in the tested endpoints.

---

# What Was Tested

The lab focused specifically on client-controlled object identifiers.

## Transfer

```json
{
  "sourceAccountId": "<UUID>"
}
```

Security boundary:

```text
authenticated user
        ↓
source account
```

---

## Beneficiary

```http
DELETE /api/beneficiaries/{id}
```

Security boundary:

```text
authenticated user
        ↓
beneficiary object
```

In both cases, the server correctly prevented cross-user object access.

---

# Key Takeaways

Object identifiers are not authorization controls.

A UUID may be difficult to guess, but applications must still verify that the authenticated principal is authorized to access the referenced object.

The important security condition is not:

```text
Does this object exist?
```

but:

```text
Does this object exist
AND
is the authenticated user allowed to act on it?
```

The tests also demonstrated the value of changing one security-relevant variable at a time.

For the beneficiary test:

```text
same authenticated user
same endpoint
same HTTP method
different object ID
```

For the transfer test:

```text
same authenticated user
same endpoint
same transfer parameters
different sourceAccountId
fresh Idempotency-Key
```

This made it possible to isolate the authorization decision from unrelated application behavior.

---

# Skills Demonstrated

- Burp Suite Proxy
- Burp Suite HTTP history
- Burp Suite Repeater
- request interception
- authenticated API testing
- bearer JWT usage
- object identifier manipulation
- BOLA / IDOR methodology
- server-side authorization validation
- HTTP status interpretation
- ownership-boundary testing
- state-changing request analysis
- idempotency awareness
- manual security verification

---

# Conclusion

Two object-level authorization boundaries were tested in SecureBank.

An authenticated user could not initiate a transfer from another user's account by modifying `sourceAccountId`.

The application returned:

```text
403 Forbidden
```

An authenticated user could also not delete another user's beneficiary by replacing the beneficiary ID.

The application returned:

```text
404 Not Found
```

and the beneficiary remained intact.

The tested endpoints therefore demonstrated effective server-side object ownership enforcement.

The lab also highlighted an important testing consideration: state-changing endpoints may use idempotency controls, and these controls must be accounted for when replaying modified requests.

The purpose of the lab was not simply to obtain successful or unsuccessful HTTP responses, but to verify whether SecureBank's authorization decisions remained correct when client-controlled resource identifiers were deliberately manipulated.