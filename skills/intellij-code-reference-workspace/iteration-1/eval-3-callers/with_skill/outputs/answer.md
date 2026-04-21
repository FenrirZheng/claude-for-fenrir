# Callers of `OrderCommonRuleService`

**Class:** `we.business.order.audit.OrderCommonRuleService`
**Defined at:** `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java:11`

Registered as Spring bean via `@Component("OrderCommonRuleService")`. Implements `we.rule.engine.SimpleRuleService<Map<String, Object>>`.

## Direct in-code invocations of `execute(...)` / `supports(...)`

There are **no direct Java call sites** in the codebase that invoke `OrderCommonRuleService.execute(...)` or `OrderCommonRuleService.supports(...)` by receiver of type `OrderCommonRuleService`.

- `supports(Map<String, Object>)` — called only from **within the class itself**:
  - `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderCommonRuleService.java:27` — inside its own `execute(...)` method (`if (supports(parameters)) { ... }`).
  - No external callers (not even the subclass `OrderRuleService`, which fully overrides `execute` and does not delegate to `supports`).

- `execute(Map<String, Object>)` — no direct static/receiver-typed call sites to `OrderCommonRuleService#execute`. It is:
  - Overridden by the subclass (see below), so the base implementation is effectively shadowed when `OrderRuleService` is the bean.
  - Invoked dynamically through the Spring rule-engine framework (see "Framework wiring" below).

## Subclass / override relationship

- `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderRuleService.java:26` — `public class OrderRuleService extends OrderCommonRuleService` (own Spring bean `@Component("OrderRuleService")`).
  - `OrderRuleService.java:33` — `@Override public MatchResult execute(Map<String, Object> parameters)` — overrides without calling `super.execute(...)`.
  - `OrderRuleService` does **not** override `supports(...)` and does **not** call it either.

## Framework wiring (how it actually gets invoked at runtime)

`OrderCommonRuleService` is invoked only through Spring's `ApplicationContext.getBean(name, SimpleRuleService.class)` — the bean name `"OrderCommonRuleService"` is looked up from a DB-configured rule row and dispatched. The single call chain that can reach `OrderCommonRuleService.execute(...)`:

1. `/home/fenrir/code/casa/we/we-starters/we-starter-security/src/main/java/we/actuate/audit/rule/DefaultOrganizationAuditRuleService.java:109-111`
   ```java
   matchResult = ruleEngineService
       .getSimpleRuleService(rule.getRules())
       .execute(parameters);
   ```
   Here `rule.getRules()` supplies the Spring bean name. If the `audit_organization_rules` DB row has `rules = "OrderCommonRuleService"`, this resolves to the bean defined at `OrderCommonRuleService.java:11` and calls its `execute(...)`.

2. `/home/fenrir/code/casa/we/we-starters/we-starter-rule-engine/src/main/java/we/rule/engine/DefaultRuleEngineService.java:16-18` — `getSimpleRuleService(String name)` returns `applicationContext.getBean(name, SimpleRuleService.class)` (generic bean-by-name lookup).

No other `.getSimpleRuleService(...)` or `.execute(...)` site in the repo is parameterised with the string `"OrderCommonRuleService"`, and the string literal `"OrderCommonRuleService"` appears only once — at the `@Component` annotation itself (`OrderCommonRuleService.java:10`). So the only runtime entry point is the generic rule-engine dispatch above, keyed by DB content.

## Summary

| Method | Direct callers (file:line) |
|---|---|
| `OrderCommonRuleService.supports` | `OrderCommonRuleService.java:27` (self-call inside `execute`) — no external Java callers |
| `OrderCommonRuleService.execute` | no direct Java call sites with `OrderCommonRuleService`-typed receiver; invoked dynamically via Spring bean lookup at `DefaultOrganizationAuditRuleService.java:109-111` when a DB `audit_organization_rules.rules` value equals `"OrderCommonRuleService"` |

Not dead code, but not directly called either — this is a rule-engine plugin invoked by name through Spring. Renaming it safely requires updating both the `@Component` bean name and any `audit_organization_rules.rules` DB values that reference it.
