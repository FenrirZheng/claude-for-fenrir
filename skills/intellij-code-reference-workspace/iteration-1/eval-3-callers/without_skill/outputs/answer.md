# Callers of `OrderCommonRuleService` methods (`execute`, `supports`)

## Class under analysis

- `we.business.order.audit.OrderCommonRuleService`
  - File: `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java`
  - Spring component, registered with bean name `"OrderCommonRuleService"` (line 10).
  - Implements `we.rule.engine.SimpleRuleService<Map<String, Object>>`.
  - Has one direct subclass: `we.business.order.audit.OrderRuleService` (`OrderRuleService.java:26`), which `@Override`s `execute(...)` (so the parent `execute` is **not** called via `super` from the subclass) but inherits `supports(...)`.

There are **no direct/static call sites** in the codebase that reference `OrderCommonRuleService` as a typed receiver (no `someVar.execute(...)` or `someVar.supports(...)` where the static type is `OrderCommonRuleService`). All invocations are reached via either (a) interface-typed dispatch through `SimpleRuleService` after a Spring bean-name lookup, or (b) inheritance from the `OrderRuleService` subclass, or (c) an internal `this.supports(...)` call.

---

## `OrderCommonRuleService.execute(Map<String, Object>)`

### 1. Dynamic Spring-bean dispatch (only external caller of the interface method)
Looked up by bean name string and invoked through the `SimpleRuleService` interface:

- `/home/fenrir/code/casa/we/we-starters/we-starter-security/src/main/java/we/actuate/audit/rule/DefaultOrganizationAuditRuleService.java:111`
  ```java
  matchResult = ruleEngineService
      .getSimpleRuleService(rule.getRules())   // line 110 — bean name from AuditRule config
      .execute(parameters);                    // line 111 — interface call
  ```
  The bean lookup itself is implemented in:
  - `/home/fenrir/code/casa/we/we-starters/we-starter-rule-engine/src/main/java/we/rule/engine/DefaultRuleEngineService.java:16-17`
    ```java
    public SimpleRuleService getSimpleRuleService(String name) {
      return applicationContext.getBean(name, SimpleRuleService.class);
    }
    ```
  This call site reaches `OrderCommonRuleService.execute` whenever an `AuditRule.rules` configuration value resolves to the bean name `"OrderCommonRuleService"` (the only place that string literal is declared is on the `@Component` annotation at `OrderCommonRuleService.java:10`).

### 2. No `super.execute(...)` from the subclass
`OrderRuleService.execute` (`OrderRuleService.java:33-90`) overrides and **does not** call `super.execute(...)`, so the parent body is never reached through the subclass.

---

## `OrderCommonRuleService.supports(Map<String, Object>)`

### 1. Internal self-call (within the class)
- `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java:27`
  ```java
  if (supports(parameters)) {
      matchResult.setMatches(2);
  }
  ```
  Called from `OrderCommonRuleService.execute` itself.

### 2. No external callers
A project-wide search (IntelliJ text index + ripgrep) found **zero** call sites of `.supports(parameters)` (or any `.supports(...)` form) outside the class itself. The `SimpleRuleService` interface only declares `execute(...)`; `supports(...)` is a public method added on the implementation but never referenced by any external code, including `OrderRuleService` (which simply re-implements the same gate logic inline at `OrderRuleService.java:40`).

---

## Summary table

| Method | File:Line | Kind |
|---|---|---|
| `execute` | `we/we-starters/we-starter-security/src/main/java/we/actuate/audit/rule/DefaultOrganizationAuditRuleService.java:111` | Dynamic Spring bean lookup → interface call (reached when `AuditRule.rules == "OrderCommonRuleService"`) |
| `supports` | `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java:27` | Internal self-call from `execute` |

No other invocations exist in the monorepo.

## Notes on methodology
- Verified via both IntelliJ text/symbol index (`mcp__idea__search_in_files_by_text`, `find_files_by_name_keyword`) and ripgrep.
- Because dispatch is by Spring bean name string (`@Component("OrderCommonRuleService")`), there is no statically-typed call site; the only way `execute` can run on this exact class is when the `AuditRule.rules` column / config feeds the literal `"OrderCommonRuleService"` into `RuleEngineService.getSimpleRuleService(...)`. That literal does not appear anywhere in the source other than the `@Component` declaration, so any actual runtime usage is driven by data (DB-stored audit rules).
