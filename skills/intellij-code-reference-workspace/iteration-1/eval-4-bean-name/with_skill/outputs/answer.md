# Spring Bean: `OrderWorkflowAuditStrategy`

## Bean registration (@Bean method)

- `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderAuditAutoConfiguration.java:13` — `@Bean public OrderWorkflowAuditStrategy orderWorkflowAuditStrategy()` inside `@Configuration @ComponentScan` class `OrderAuditAutoConfiguration` (line 10). Bean name defaults to the method name: **`orderWorkflowAuditStrategy`**.

## Class definition (no stereotype — bean exists only via the @Bean factory above)

- `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderWorkflowAuditStrategy.java:17` — `public class OrderWorkflowAuditStrategy extends WorkflowAuditStrategy`. The class itself has NO `@Component`/`@Service`/`@Repository`; it is registered solely through the `@Bean` factory method above.

## Name-based lookup / injection

No direct by-name injection was found in Java source:
- No `@Qualifier("orderWorkflowAuditStrategy")`
- No `@Resource(name = "orderWorkflowAuditStrategy")`
- No `getBean("orderWorkflowAuditStrategy")`
- No `@Autowired` field of type `OrderWorkflowAuditStrategy`

The bean is instead discovered and registered **by type + strategy name** via a strategy-pattern registry:

- `we/we-starters/we-starter-security/src/main/java/we/actuate/audit/strategy/AuditStrategyDispatch.java:30-32` — `applicationContext.getBeansOfType(AuditStrategy.class)` iterates every `AuditStrategy` bean and stores each by `getStrategyName()`:
  ```java
  strategyMap.put(e.getValue().getStrategyName(), e.getValue())
  ```
- `OrderWorkflowAuditStrategy.java:23-25` — `getStrategyName()` returns the string `"OrderWorkflowAuditStrategy"`, which is the key used at runtime (not the Spring bean name).
- Runtime dispatch: `AuditStrategyDispatch.java:84,89` — `getAuditStrategy(option.getStrategy())` resolves the strategy by that string key.

### Frontend reference to the strategy key

- `smart-park-admin/src/utils/request.js:98` — JS code references the literal `'OrderWorkflowAuditStrategy'` (paired with `'BillWorkflowAuditStrategy'`), presumably sent from the client and resolved server-side through `AuditStrategyDispatch.getAuditStrategy(...)`.

## Summary

| Role | Location |
|---|---|
| `@Bean` registration (bean name `orderWorkflowAuditStrategy`) | `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderAuditAutoConfiguration.java:13` |
| Class definition | `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderWorkflowAuditStrategy.java:17` |
| Strategy-key self-identification | `.../OrderWorkflowAuditStrategy.java:24` (returns `"OrderWorkflowAuditStrategy"`) |
| Runtime registry that indexes it by `getStrategyName()` | `we/we-starters/we-starter-security/src/main/java/we/actuate/audit/strategy/AuditStrategyDispatch.java:30-32` |
| Runtime lookup by name | `AuditStrategyDispatch.java:84` and `:89` via `getAuditStrategy(option.getStrategy())` |
| Client-side reference to the strategy key | `smart-park-admin/src/utils/request.js:98` |

No Spring-level by-name lookups of `orderWorkflowAuditStrategy` exist. All consumption is polymorphic via `AuditStrategy`/`WorkflowAuditStrategy` + the dispatch map keyed by the `getStrategyName()` string.
