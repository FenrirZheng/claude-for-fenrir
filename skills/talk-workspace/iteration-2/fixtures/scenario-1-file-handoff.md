# Top 3 security risks — internal/exchangeapi/auth/handlers.go

1. **JWT has no revocation / denylist.** Leaked or pre-logout JWTs stay valid for the full 15-minute expiry. Fix: add a jti-keyed denylist in redis with TTL matching exp.

2. **/v6/jwt/me leaks the password hash.** The handler returns the full users row; `password_hash` is exposed even on routine profile reads. Fix: project through a DTO.

3. **Login path is a user-enumeration timing oracle.** Missing users short-circuit before argon2 runs, so response time distinguishes existing from non-existent accounts. Fix: run a dummy argon2 on a fixed-cost hash when the lookup misses.
