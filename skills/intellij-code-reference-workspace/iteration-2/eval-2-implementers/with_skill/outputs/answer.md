# Classes extending `WorkflowAuditStrategy`

Base class:
- `we/we-starters/we-starter-security/src/main/java/we/actuate/audit/strategy/WorkflowAuditStrategy.java:9` — `public class WorkflowAuditStrategy implements AuditStrategy<ResponseEntity>`

Subclasses (direct `extends WorkflowAuditStrategy`):

1. `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderWorkflowAuditStrategy.java:17` — `public class OrderWorkflowAuditStrategy extends WorkflowAuditStrategy`
2. `we-business-order-starter/we-business-billing/we-business-payment-service/src/main/java/we/business/order/payment/service/BillWorkflowAuditStrategy.java:32` — `@Component("BillWorkflowAuditStrategy") public class BillWorkflowAuditStrategy extends WorkflowAuditStrategy`
3. `we-business-order-starter/we-business-order-audit/src/main/java/we/business/order/audit/OrderReturnWorkflowAuditStrategy.java:12` — `public class OrderReturnWorkflowAuditStrategy extends WorkflowAuditStrategy`

Total: 3 direct subclasses. Verified via `mcp__idea__search_symbol` and cross-checked with `mcp__idea__search_in_files_by_regex` (pattern `extends\s+WorkflowAuditStrategy\b`) — both returned the same 3 subclasses.
