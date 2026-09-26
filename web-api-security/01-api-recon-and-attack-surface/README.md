# Lab 05 — API Reconnaissance and Attack-Surface Mapping

## Overview

This lab moves the SecureBank security-testing workflow from network reconnaissance into application and API security.

The previous labs established:

- what information is visible over HTTP and HTTPS
- which Docker services are exposed
- what services an attacker can enumerate
- which services should remain reachable from the attacker network

This lab asks the next question:

> What API endpoints, parameters, object identifiers, authentication mechanisms, and authorization boundaries can an authenticated tester discover by observing SecureBank from the outside?

The application was treated as a black-box target from the tester's perspective.

The API surface was discovered by interacting with the SecureBank frontend through Burp Suite rather than by reading the backend source code or copying routes from implementation files.

No authorization bypasses or object-manipulation attacks were attempted during this lab.

The purpose was reconnaissance and attack-surface mapping only.

---

## Lab Summary

**Objective:** Map the authenticated customer-facing SecureBank API from externally observable browser traffic.

**Tester:**

```text
Kali Linux
192.168.56.10
```

**Target:**

```text
SecureBank
https://securebank.lab:3443
192.168.56.20
```

**Tools:**

- Burp Suite Community Edition
- Burp Proxy
- Burp HTTP history
- Chromium-based Burp browser
- Keycloak
- JWT bearer authentication
- SecureBank API
- HTTPS

---

## Security Question

The primary question was:

> What parts of the SecureBank API can an authenticated customer discover and control through normal application interaction?

Additional questions included:

- Which API endpoints does the frontend call?
- Which HTTP methods are used?
- How is authentication represented?
- Does the client send a user ID?
- Which object identifiers are exposed to the client?
- Which identifiers can the client send back to the API?
- Which query parameters and request-body fields are user controlled?
- Which endpoints represent meaningful authorization boundaries?
- Which API requests are useful candidates for later BOLA/IDOR testing?
- Which controls should be tested separately in later labs?

---

## Lab Architecture

```text
Kali Linux
192.168.56.10
      │
      │ Burp browser
      ▼
Burp Suite Proxy
      │
      │ HTTPS
      ▼
securebank.lab:3443
192.168.56.20
      │
      ▼
    Nginx
      │
      ├── /auth/* ──> Keycloak
      │
      └── /api/* ───> SecureBank API
```

Burp acts as an intercepting proxy between the browser and SecureBank.

This allows the tester to observe:

- HTTP methods
- request paths
- query parameters
- request bodies
- Authorization headers
- response bodies
- object identifiers
- response status codes

---

## 1. Starting Burp Suite

Burp Suite was launched on Kali:

```bash
burpsuite
```

A temporary project was used with Burp's default configuration.

The built-in Burp browser was used rather than manually configuring an external browser proxy.

The SecureBank application was opened at:

```text
https://securebank.lab:3443
```

The browser was routed through Burp automatically.

---

## 2. Observing the Authentication Flow

The initial request was intercepted and forwarded through Burp.

SecureBank redirected the browser into the Keycloak login flow.

The tester authenticated normally using the existing SecureBank customer account.

The observed sequence was conceptually:

```text
SecureBank
    │
    ▼
Keycloak authorization request
    │
    ▼
Login
    │
    ▼
Authorization response
    │
    ▼
SecureBank
    │
    ▼
Authenticated API calls
```

After authentication, Burp Intercept was disabled and HTTP history was used for passive API mapping.

This made it possible to browse the application normally while Burp continued recording requests.

---

## 3. Authentication Mechanism

Authenticated API requests contained:

```http
Authorization: Bearer <JWT>
```

The access token exposed several useful claims when decoded.

Observed claims included:

```text
iss = https://securebank.lab:3443/auth/realms/securebank
aud = securebank-api
azp = securebank-web
role = customer
sub = authenticated Keycloak user identifier
```

The token lifetime observed from `iat` and `exp` was approximately five minutes.

### Security Observation

The customer API does not require the browser to send a separate user ID for normal user-scoped list operations.

Instead:

```text
Bearer JWT
    │
    ▼
sub claim
    │
    ▼
server-side user context
    │
    ▼
user-scoped query
```

This reduces one obvious form of IDOR/BOLA input because the caller cannot simply replace a `userId` query or path parameter.

However, object-level identifiers still appear elsewhere in the API.

---

## 4. Discovered Customer API Surface

The following customer-facing endpoints were observed through normal application use:

```text
GET    /api/auth/me

GET    /api/accounts

GET    /api/transfers
       ?page=
       &pageSize=
       &sortBy=
       &sortDirection=

POST   /api/transfers

GET    /api/beneficiaries

POST   /api/beneficiaries

DELETE /api/beneficiaries/{id}
```

These endpoints were discovered from Burp HTTP history rather than backend source code.

---

# Endpoint Analysis

## 5. `GET /api/accounts`

Observed request:

```http
GET /api/accounts HTTP/1.1
Host: securebank.lab:3443
Authorization: Bearer <redacted>
Accept: application/json
```

No user ID or account ID was supplied in the request.

The response returned the authenticated user's account:

```json
[
  {
    "id": "a80402f2-6f05-4912-b850-e6cac5b13665",
    "accountNumber": "SI560000000000000001",
    "balance": 1000.00,
    "currency": "EUR",
    "status": "Active",
    "createdAt": "2026-09-26T12:10:38.360668+00:00"
  }
]
```

### Observed Fields

```text
id
accountNumber
balance
currency
status
createdAt
```

### Security-Relevant Identifiers

```text
account ID
account number
```

### Authorization Boundary

The request itself does not identify the user.

The backend therefore needs to derive the customer identity from the authenticated security context and return only accounts belonging to that user.

Conceptually:

```text
GET /api/accounts
        │
        ├── no userId
        │
        └── Bearer JWT
                │
                ▼
              sub
                │
                ▼
        server-side user context
                │
                ▼
        authenticated user's accounts
```

### Reconnaissance Result

| Property | Observation |
| --- | --- |
| Method | `GET` |
| Endpoint | `/api/accounts` |
| Authentication | Bearer JWT |
| User ID supplied by client | No |
| Object IDs returned | Yes |
| Interesting identifiers | Account GUID, account number |
| Client-controlled body | None |
| Authorization boundary | Results must be scoped to authenticated subject |

---

## 6. `GET /api/transfers`

Observed request:

```http
GET /api/transfers?page=1&pageSize=25&sortBy=createdAt&sortDirection=desc HTTP/1.1
Host: securebank.lab:3443
Authorization: Bearer <redacted>
Accept: application/json
```

The endpoint accepts several client-controlled query parameters:

```text
page
pageSize
sortBy
sortDirection
```

Observed response:

```json
{
  "page": 1,
  "pageSize": 25,
  "totalItems": 1,
  "totalPages": 1,
  "hasPreviousPage": false,
  "hasNextPage": false,
  "items": [
    {
      "id": "2b778794-d59b-4112-bfe6-e601807947ef",
      "sourceAccountId": "a80402f2-6f05-4912-b850-e6cac5b13665",
      "destinationAccountId": "5168bcc2-cf7a-4b02-a4a4-a6c7ad6ee55a",
      "amount": 10.00,
      "currency": "EUR",
      "status": "Completed",
      "createdAt": "2026-09-26T15:28:26.746817+00:00"
    }
  ]
}
```

### Object Identifiers Exposed

```text
transfer ID
source account ID
destination account ID
```

### Security Observation

The endpoint does not accept a user identifier.

Therefore the transfer list must remain scoped to the authenticated subject.

The response also reveals related object identifiers that may become useful during later authorization testing.

### Reconnaissance Result

| Property | Observation |
| --- | --- |
| Method | `GET` |
| Endpoint | `/api/transfers` |
| Authentication | Bearer JWT |
| User ID supplied by client | No |
| Query parameters | `page`, `pageSize`, `sortBy`, `sortDirection` |
| Object IDs returned | Transfer ID, source account ID, destination account ID |
| Authorization boundary | Results must be scoped to authenticated user |
| Additional input surface | Pagination and sorting |

Malformed pagination or sorting was not tested during this reconnaissance lab.

---

## 7. `POST /api/transfers`

Observed request body:

```json
{
  "sourceAccountId": "a80402f2-6f05-4912-b850-e6cac5b13665",
  "destinationAccountNumber": "SI560000000000000002",
  "amount": 5,
  "currency": "EUR"
}
```

The request also included:

```http
Idempotency-Key: 7f1f571b-144f-45e3-a6a3-9069eb732426
```

Successful response:

```json
{
  "transferId": "87e8dba2-5dfd-4b18-a714-5b1c6ccf4c3c"
}
```

### Client-Controlled Inputs

```text
sourceAccountId
destinationAccountNumber
amount
currency
Idempotency-Key
```

### Critical Authorization Boundary

`sourceAccountId` is supplied directly by the client.

This creates an important object-level authorization decision:

```text
Authenticated JWT subject
          +
client-supplied sourceAccountId
          │
          ▼
Does this account belong to this user?
```

Authentication alone is not sufficient.

The backend must verify ownership of the specified source account before allowing a transfer.

### Future BOLA Test

A later lab can replace:

```text
sourceAccountId = user's own account
```

with:

```text
sourceAccountId = another customer's account
```

and verify that the request is rejected.

No such manipulation was performed during this reconnaissance lab.

### Idempotency Boundary

The request also exposes a separate security control:

```http
Idempotency-Key: <UUID>
```

This creates a future replay-testing question:

> Does resending the same transfer with the same idempotency key execute the financial operation more than once?

That control will be tested separately.

### Reconnaissance Result

| Property | Observation |
| --- | --- |
| Method | `POST` |
| Endpoint | `/api/transfers` |
| Authentication | Bearer JWT |
| Client-controlled object ID | `sourceAccountId` |
| Client-controlled destination | `destinationAccountNumber` |
| Other input | `amount`, `currency` |
| Additional security control | `Idempotency-Key` |
| Authorization boundary | Source account must belong to authenticated user |
| Success response | `transferId` |

---

## 8. `GET /api/beneficiaries`

Observed response:

```json
[
  {
    "id": "04127384-c201-4111-b4e1-d755eaee6e13",
    "accountId": "5168bcc2-cf7a-4b02-a4a4-a6c7ad6ee55a",
    "accountNumber": "SI560000000000000002",
    "nickname": "Demo recipient",
    "createdAt": "2026-09-26T12:10:38.638063+00:00"
  }
]
```

### Exposed Fields

```text
id
accountId
accountNumber
nickname
createdAt
```

The response exposes both:

```text
beneficiary ID
```

and:

```text
related account ID
```

The account ID matched the destination account previously observed in transfer history.

This allows the tester to begin understanding relationships between API objects.

```text
Beneficiary
    │
    └── accountId
            │
            └── destination account observed in transfers
```

### Reconnaissance Result

| Property | Observation |
| --- | --- |
| Method | `GET` |
| Endpoint | `/api/beneficiaries` |
| Authentication | Bearer JWT |
| User ID supplied | No |
| Object IDs returned | Beneficiary ID, account ID |
| Other fields | Account number, nickname, creation timestamp |
| Authorization boundary | Results must be scoped to authenticated user |

---

## 9. `POST /api/beneficiaries`

Observed request:

```json
{
  "accountNumber": "SI560000000000000002",
  "nickname": "New"
}
```

Successful response:

```json
{
  "beneficiaryId": "04127384-c201-4111-b4e1-d755eaee6e13"
}
```

### Client-Controlled Inputs

```text
accountNumber
nickname
```

Saving another person's account number as a beneficiary is expected banking behavior and does not by itself represent an authorization weakness.

The more important authorization boundary appears when an existing beneficiary is modified or deleted.

### Reconnaissance Result

| Property | Observation |
| --- | --- |
| Method | `POST` |
| Endpoint | `/api/beneficiaries` |
| Authentication | Bearer JWT |
| Client-controlled object reference | Account number |
| Other input | Nickname |
| User ID supplied | No |
| Object ID returned | Beneficiary ID |
| Authorization boundary | Created beneficiary must be associated with authenticated user |

---

## 10. `DELETE /api/beneficiaries/{id}`

Observed request:

```http
DELETE /api/beneficiaries/04127384-c201-4111-b4e1-d755eaee6e13 HTTP/1.1
Host: securebank.lab:3443
Authorization: Bearer <redacted>
```

Successful response:

```text
HTTP/1.1 200 OK
Content-Length: 0
```

The beneficiary GUID is therefore directly controlled through the URL.

### Critical Authorization Boundary

The backend must verify:

```text
authenticated JWT subject
          +
beneficiary ID from URL
          │
          ▼
Does this beneficiary belong to this user?
```

The endpoint must not assume that authentication grants permission to delete every beneficiary object.

### Future BOLA Test

A later lab can compare:

```text
DELETE own beneficiary ID
→ succeeds
```

with:

```text
DELETE another user's beneficiary ID
→ must be rejected
```

### Reconnaissance Result

| Property | Observation |
| --- | --- |
| Method | `DELETE` |
| Endpoint | `/api/beneficiaries/{id}` |
| Authentication | Bearer JWT |
| Client-controlled object ID | Beneficiary GUID |
| User ID supplied | No |
| Authorization boundary | Beneficiary ownership must be verified |
| Success response | `200 OK` |

---

# Object Relationship Mapping

## 11. Discovered Object Graph

The observed API responses revealed relationships between several objects.

```text
Authenticated User
       │
       ├── Account
       │     │
       │     └── accountId
       │
       ├── Transfer
       │     ├── transferId
       │     ├── sourceAccountId
       │     └── destinationAccountId
       │
       └── Beneficiary
             ├── beneficiaryId
             └── accountId
```

The same destination account identifier appeared in both:

```text
transfer.destinationAccountId
```

and:

```text
beneficiary.accountId
```

This is useful reconnaissance information because object relationships often reveal where authorization controls need to be tested.

---

# Trust Boundary Analysis

## 12. Identity vs Resource Identifiers

One of the most important observations from the lab is that SecureBank uses two different classes of security-relevant data.

### Identity

Identity comes from the authenticated token:

```text
JWT
 │
 └── sub
       │
       ▼
 authenticated user
```

### Resource Identifiers

Object identifiers may come from untrusted client input:

```text
sourceAccountId

beneficiaryId

destinationAccountNumber
```

The backend must combine these correctly.

```text
trusted identity
      +
untrusted resource identifier
      │
      ▼
authorization decision
```

This is a core application-security boundary.

---

## 13. Identified Authorization Test Candidates

The reconnaissance phase identified two strong BOLA/IDOR candidates.

### Transfer Source Account

```text
POST /api/transfers
```

Client-controlled value:

```text
sourceAccountId
```

Security requirement:

> The authenticated user must own the source account.

### Beneficiary Deletion

```text
DELETE /api/beneficiaries/{id}
```

Client-controlled value:

```text
beneficiaryId
```

Security requirement:

> The beneficiary must belong to the authenticated user.

These will be tested in the next application-security lab.

---

# Additional Test Candidates

## 14. Transfer Replay

Observed control:

```http
Idempotency-Key: <UUID>
```

Future question:

> Does replaying the same financial request execute the transfer more than once?

---

## 15. JWT Validation

Observed claims provide future test targets:

```text
iss
aud
exp
sub
roles
azp
```

Potential later tests include:

- expired token
- incorrect audience
- incorrect issuer
- modified role claim
- modified subject
- invalid signature

These were not tested during reconnaissance.

---

## 16. Pagination and Sorting

Observed parameters:

```text
page
pageSize
sortBy
sortDirection
```

Potential future tests include:

- invalid page numbers
- oversized page sizes
- unsupported sort fields
- malformed sort directions

These inputs were only mapped during this lab.

---

# API Attack-Surface Inventory

## 17. Final Customer API Map

| Method | Endpoint | Client-Controlled Input | Key Security Boundary |
| --- | --- | --- | --- |
| `GET` | `/api/auth/me` | None | Return authenticated identity only |
| `GET` | `/api/accounts` | None | Scope accounts to JWT subject |
| `GET` | `/api/transfers` | Pagination/sorting | Scope transfers to JWT subject |
| `POST` | `/api/transfers` | Source account, destination, amount, currency, idempotency key | Verify source-account ownership |
| `GET` | `/api/beneficiaries` | None | Scope beneficiaries to JWT subject |
| `POST` | `/api/beneficiaries` | Account number, nickname | Associate object with authenticated user |
| `DELETE` | `/api/beneficiaries/{id}` | Beneficiary ID | Verify beneficiary ownership |

---

# Security Observations

## Positive Design Observation — User-Scoped Collection Endpoints

Several collection endpoints do not accept a client-supplied user ID:

```text
GET /api/accounts
GET /api/transfers
GET /api/beneficiaries
```

Instead, identity is derived from the authenticated user context.

This removes one obvious client-controlled authorization input.

However, the implementation must still correctly scope all returned data to the authenticated subject.

---

## Security Observation — Object IDs Remain Important

The absence of a user ID in the route does not eliminate BOLA risk.

Object identifiers are still exposed and accepted elsewhere.

Examples include:

```text
sourceAccountId

beneficiaryId

destinationAccountId

accountId
```

Therefore:

```text
no userId parameter
≠
no object-level authorization boundary
```

---

## Security Observation — Bearer Tokens Are Credentials

Burp exposes the complete Authorization header:

```http
Authorization: Bearer <JWT>
```

A bearer token should be treated as a temporary credential.

Screenshots, documentation, and committed evidence should therefore redact the token value.

Recommended representation:

```http
Authorization: Bearer <redacted>
```

---

# Reconnaissance Workflow

The lab followed this sequence:

```text
Launch Burp
      ↓
Use Burp browser
      ↓
Authenticate normally
      ↓
Observe OIDC flow
      ↓
Disable active interception
      ↓
Browse SecureBank normally
      ↓
Inspect HTTP history
      ↓
Filter /api/ traffic
      ↓
Record methods and routes
      ↓
Inspect request parameters
      ↓
Inspect response objects
      ↓
Map identifiers
      ↓
Identify authorization boundaries
      ↓
Select targets for later testing
```

---

# Why Reconnaissance Comes Before Exploitation

It would have been possible to use knowledge of the SecureBank source code to select endpoints immediately.

That was deliberately avoided.

From a security-testing perspective, the workflow should instead ask:

```text
What does an external authenticated user actually observe?
```

This mirrors the approach used during network enumeration:

```text
do not assume the exposed ports
→ scan them
```

and now:

```text
do not assume the API surface
→ observe it
```

Reconnaissance provides the evidence used to decide what should be tested next.

---

# Key Takeaways

Through this lab I practiced:

- configuring and using Burp Suite as an intercepting proxy
- using Burp's integrated browser
- observing an OIDC authentication flow
- using HTTP history for passive reconnaissance
- identifying API endpoints from browser traffic
- distinguishing GET, POST, and DELETE operations
- inspecting Bearer JWT authentication
- identifying relevant JWT claims
- mapping query parameters
- mapping JSON request bodies
- identifying client-controlled inputs
- mapping object identifiers from API responses
- correlating identifiers across related resources
- distinguishing user identity from object identifiers
- identifying object-level authorization boundaries
- identifying future BOLA/IDOR test cases
- identifying replay/idempotency test opportunities
- treating bearer tokens as credentials
- building an API attack-surface inventory without relying on source code

---

# Security Engineering Workflow

This lab extends the recurring portfolio workflow:

```text
Observe
   ↓
Map
   ↓
Analyze trust boundaries
   ↓
Identify test candidates
   ↓
Test later
```

In the broader portfolio:

```text
Network reconnaissance
        ↓
Service exposure
        ↓
Firewall boundaries
        ↓
API reconnaissance
        ↓
Object authorization testing
```

---

# Future Work

The next labs can use the reconnaissance results to test:

- BOLA/IDOR on transfer source accounts
- BOLA/IDOR on beneficiary deletion
- horizontal authorization boundaries
- vertical authorization boundaries
- JWT validation
- replay and idempotency
- pagination and sorting validation
- rate limiting
- API error behavior

---

# Conclusion

This lab mapped the authenticated SecureBank customer API using Burp Suite from an external tester perspective.

The application exposed several user-scoped collection endpoints that derive identity from the authenticated JWT rather than accepting a user ID directly.

However, reconnaissance also identified multiple client-controlled object references.

The most important were:

```text
POST /api/transfers
→ sourceAccountId
```

and:

```text
DELETE /api/beneficiaries/{id}
→ beneficiaryId
```

These identifiers cross an authorization boundary because the server must determine whether the authenticated user is allowed to operate on the referenced object.

The transfer request also exposed an idempotency control that can later be tested for replay resistance.

The resulting attack-surface map provides the evidence and targets required for the next lab:

> BOLA / IDOR testing against SecureBank object-level authorization controls.