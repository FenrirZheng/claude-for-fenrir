# Classes extending `WorkflowAuditStrategy`

Base class: `we.actuate.audit.strategy.WorkflowAuditStrategy`
- `/home/fenrir/code/casa/we/we-starters/we-starter-security/src/main/java/we/actuate/audit/strategy/WorkflowAuditStrategy.java:12` — `public class WorkflowAuditStrategy implements AuditStrategy<ResponseEntity>`

## Direct subclasses (3)

1. **`BillWorkflowAuditStrategy`** (package `we.business.order.payment.service`)
   - `/home/fenrir/code/casa/we-business-order-starter/we-business-billing/we-business-payment-service/src/main/java/we/business/order/payment/service/BillWorkflowAuditStrategy.java:32`
   - Annotated `@Component("BillWorkflowAuditStrategy")`

2. **`OrderReturnWorkflowAuditStrategy`** (package `we.business.order.audit`)
   - `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderReturnWorkflowAuditStrategy.java:12`
   - Note: file has `//todo 可能无法直接使用` and most logic is commented out.

3. **`OrderWorkflowAuditStrategy`** (package `we.business.order.audit`)
   - `/home/fenrir/code/casa/we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderWorkflowAuditStrategy.java:17`
   - Registered as a `@Bean` in `OrderAuditAutoConfiguration` (same package).

No further (transitive) subclasses found.

## Method used
IntelliJ MCP: `mcp__idea__search_symbol` then cross-checked with `mcp__idea__search_regex` for `extends\s+WorkflowAuditStrategy\b` across `**/*.java`. Both returned the same 3 direct subclasses.
