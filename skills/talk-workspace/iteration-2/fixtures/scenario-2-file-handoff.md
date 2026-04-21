# Integration test regressions — wallet service

3 regressions, all in `internal/exchangeapi/wallet/`:

1. **TestWithdraw_InsufficientBalance** — error code regression: returns `UNKNOWN` instead of `INSUFFICIENT_BALANCE`. Likely commit that touched the error mapping layer.

2. **TestWithdraw_ConcurrentRequests** — lock timeout + balance drift under concurrent withdrawals. Smells like missing `SELECT FOR UPDATE` or row lock on the balances table.

3. **TestDeposit_IdempotencyKey** — duplicate deposit with same idempotency-key is accepted (returns 200) instead of rejected (409). Either the check is not wired up or the key column isn't unique.

All 3 passed on main yesterday — bisect against today's 6 new commits on `feature/fenrir-backend`.
