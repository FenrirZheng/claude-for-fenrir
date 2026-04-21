# Callers of `OrderCommonRuleService` methods (`execute`, `supports`)

**Class:** `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java:11`
Spring bean name: `"OrderCommonRuleService"` (registered via `@Component("OrderCommonRuleService")` on line 10). Implements `we.rule.engine.SimpleRuleService<Map<String, Object>>`.

No code anywhere in the workspace calls `orderCommonRuleService.execute(...)` or `.supports(...)` on a typed reference — all invocations are either (a) self-calls inside the class, (b) polymorphic dispatch through the `SimpleRuleService` interface after a Spring bean-name lookup, or (c) inheritance by the `OrderRuleService` subclass.

## 1. Direct textual call sites

### `execute(...)`

- `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java:25` — declaration of `execute` (the `@Override` itself).

*No other file invokes `execute` on an `OrderCommonRuleService` reference.*

### `supports(...)`

- `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java:13` — declaration.
- `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java:27` — **self-call inside `execute`**: `if (supports(parameters)) { matchResult.setMatches(2); }`.

*No external call site invokes `supports` directly.*

## 2. Framework-level invocation (polymorphic, via Spring bean lookup)

`OrderCommonRuleService` is only reachable through the rule-engine dispatch in the security starter. The bean is fetched by name (`"OrderCommonRuleService"`) and invoked through the `SimpleRuleService` interface:

- `we/we-starters/we-starter-security/src/main/java/we/actuate/audit/rule/DefaultOrganizationAuditRuleService.java:109-111`
  ```java
  matchResult = ruleEngineService
      .getSimpleRuleService(rule.getRules())   // bean name comes from AuditRule.rules (DB-driven)
      .execute(parameters);
  ```
  This is the single runtime entry point that will call `OrderCommonRuleService.execute(...)` (and transitively its internal `supports(...)`) whenever an `AuditRule` row has `ruleEngine = JAVA` and `rules = "OrderCommonRuleService"`.

- Bean lookup implementation: `we/we-starters/we-starter-rule-engine/src/main/java/we/rule/engine/DefaultRuleEngineService.java:16-17`
  ```java
  public SimpleRuleService getSimpleRuleService(String name) {
    return applicationContext.getBean(name, SimpleRuleService.class);
  }
  ```

Because the bean name lives in the database (`AuditRule.rules` column), the literal string `"OrderCommonRuleService"` does not appear anywhere else in the source tree — `search_in_files_by_text("\"OrderCommonRuleService\"")` returned only the `@Component` declaration.

## 3. Subclass (inheritance, not a call)

- `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderRuleService.java:26` — `public class OrderRuleService extends OrderCommonRuleService`.
  - `execute` is `@Override`-n at `OrderRuleService.java:33` and does **not** call `super.execute(...)`.
  - `supports` is inherited unchanged; no explicit `super.supports(...)` call.
  - `OrderRuleService` is registered as its own Spring bean `@Component("OrderRuleService")` (line 25), so it's dispatched via the same `DefaultOrganizationAuditRuleService.java:109-111` path when `AuditRule.rules = "OrderRuleService"`.

## Summary

| Caller | File:Line | Kind |
|---|---|---|
| `OrderCommonRuleService.execute` → `supports` | `OrderCommonRuleService.java:27` | Self-call (inside the class) |
| `DefaultOrganizationAuditRuleService.audit` → `.execute` | `DefaultOrganizationAuditRuleService.java:111` | Polymorphic, bean-name dispatch via `SimpleRuleService` |
| `OrderRuleService extends OrderCommonRuleService` | `OrderRuleService.java:26` | Inheritance; overrides `execute`, inherits `supports` |

There are no other callers — `execute` and `supports` are never invoked by name on an `OrderCommonRuleService` instance anywhere in the codebase.
