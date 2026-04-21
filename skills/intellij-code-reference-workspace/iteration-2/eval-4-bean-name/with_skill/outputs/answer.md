# Spring bean `OrderWorkflowAuditStrategy` — registration and name-based lookup

## Class definition

- `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderWorkflowAuditStrategy.java:17`
  `public class OrderWorkflowAuditStrategy extends WorkflowAuditStrategy`

## Registration (@Bean factory method)

- `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderAuditAutoConfiguration.java:12-15`

  ```java
  @Bean
  public OrderWorkflowAuditStrategy orderWorkflowAuditStrategy() {
    return new OrderWorkflowAuditStrategy();
  }
  ```

  Enclosing class `OrderAuditAutoConfiguration` is `@Configuration @ComponentScan` (line 8-10). The Spring bean name derived from the factory method is `orderWorkflowAuditStrategy` (camelCase).

There is no `@Component` on the class itself, so this `@Bean` method is the only Spring registration.

## Strategy name (logical name used for name-based lookup)

- `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderWorkflowAuditStrategy.java:22-25`

  ```java
  @Override
  public String getStrategyName() {
    return "OrderWorkflowAuditStrategy";
  }
  ```

## Name-based lookup / dispatch sites

This codebase does **not** inject the bean by Spring-bean-name with `@Qualifier("orderWorkflowAuditStrategy")` anywhere. Instead it is looked up by its logical `getStrategyName()` string through a runtime registry:

1. Registry build — all `AuditStrategy` beans collected from the `ApplicationContext` and keyed by `getStrategyName()`:
   - `/home/fenrir/code/casa/we/we-starters/we-starter-security/src/main/java/we/actuate/audit/strategy/AuditStrategyDispatch.java:29-33`
     ```java
     applicationContext.getBeansOfType(AuditStrategy.class).entrySet().forEach(e ->
         strategyMap.put(e.getValue().getStrategyName(), e.getValue())
     );
     ```

2. Lookup by name — `getAuditStrategy(String name)` on that map:
   - `/home/fenrir/code/casa/we/we-starters/we-starter-security/src/main/java/we/actuate/audit/strategy/AuditStrategyDispatch.java:35-37`
     ```java
     public AuditStrategy getAuditStrategy(String name) {
       return strategyMap.get(name);
     }
     ```

3. Call sites that resolve a strategy by name at runtime (the `name` passed in is the `getStrategyName()` string, e.g. `"OrderWorkflowAuditStrategy"`):
   - `/home/fenrir/code/casa/we/we-starters/we-starter-security/src/main/java/we/actuate/audit/strategy/AuditStrategyDispatch.java:84` — `getAuditStrategy(option.getStrategy()).approveAudit(option)`
   - `/home/fenrir/code/casa/we/we-starters/we-starter-security/src/main/java/we/actuate/audit/strategy/AuditStrategyDispatch.java:89` — `getAuditStrategy(option.getStrategy()).getAuditURI(option)`

## String-literal references to the name `"OrderWorkflowAuditStrategy"`

- `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderWorkflowAuditStrategy.java:24` — returned from `getStrategyName()` (registers the key in `AuditStrategyDispatch.strategyMap`).
- `/home/fenrir/code/casa/smart-park-admin/src/utils/request.js:98` — frontend whitelists the strategy name to surface a success toast when the backend returns HTTP 209 with `codeStatus.strategy === "OrderWorkflowAuditStrategy"`:
  ```js
  const strategyMap = ['OrderWorkflowAuditStrategy', 'BillWorkflowAuditStrategy'];
  if (status === 209 && strategyMap.includes(codeStatus.strategy)) { ... }
  ```

## Summary

| Concern | Location |
|---|---|
| Class | `we-business-order-starter/we-business-order-audit/.../OrderWorkflowAuditStrategy.java:17` |
| `@Bean` registration | `we-business-order-starter/we-business-order-audit/.../OrderAuditAutoConfiguration.java:12` |
| Logical name definition | `OrderWorkflowAuditStrategy.java:23-25` (`"OrderWorkflowAuditStrategy"`) |
| Name-indexed registry build | `we/we-starters/we-starter-security/.../AuditStrategyDispatch.java:30-32` |
| Name-based lookup API | `AuditStrategyDispatch.java:35-37` (`getAuditStrategy(name)`) |
| Runtime lookup call sites | `AuditStrategyDispatch.java:84`, `:89` |
| Name string on frontend | `smart-park-admin/src/utils/request.js:98` |

No `@Qualifier("orderWorkflowAuditStrategy")`, no `ApplicationContext.getBean("orderWorkflowAuditStrategy")`, and no `@Resource(name=...)` lookups of the Spring bean name exist in this repo.
