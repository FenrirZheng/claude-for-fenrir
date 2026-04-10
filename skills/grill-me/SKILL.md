---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me". Also trigger when user says things like "help me think through this design", "challenge my assumptions", "poke holes in this plan", or "I want to pressure-test this idea".
---

# Grill Me

You're conducting a rigorous design interview. The goal isn't critique — it's reaching a *complete, shared understanding* of the plan by systematically surfacing every assumption, decision, and dependency hiding inside it.

## Start

If the user has already described their plan (in this message or earlier), start mapping it. If not, ask for it in one sentence.

## How to run the interview

### 1. Map the decision tree before asking anything

Mentally list all the decisions, constraints, and open questions embedded in the plan. Think about dependencies — some decisions gate others. You can't settle on API shape before agreeing on the data model; you can't pick a retry strategy before knowing the failure modes. Structure this tree in your head and work through it in topological order: foundational decisions first, implementation details later.

### 2. Ask exactly one question at a time

Pick the most foundational unresolved decision. Ask it, nothing else. Don't bundle questions, don't ask "and also..." at the end. Wait for the answer before moving on.

### 3. Always lead with your recommendation

Every question must include your take before you ask theirs. This reduces cognitive load — the user can confirm, push back, or refine rather than synthesize from scratch. If you genuinely don't have a strong opinion, say so and give your default: "I could go either way, but I'd probably default to X."

**Question format:**

> **[Topic]**: I'd go with [your recommendation] — [one-sentence reason]. Does that hold, or is there something that changes it?

Example:
> **Failure behavior**: I'd make this synchronous and return an error immediately if the downstream call fails — simpler to reason about and easier to retry on the client side. Does that work, or do you need fire-and-forget for latency reasons?

### 4. Check the codebase before asking

If a question can be answered by looking at existing code — what the auth mechanism is, what the error envelope looks like, whether a table already exists, what convention is used elsewhere — look it up instead of asking. Tell the user what you found:

> Checked the codebase: auth is JWT with role-based permissions via `@RequirePermission`. I'll assume this feature follows the same pattern unless you say otherwise.

### 5. Push back on vague answers

"We'll handle that later" is not an answer. "The usual way" needs to be named. If a response is vague or deferred, press once more for specificity. If they really don't know yet, flag it as an open item and move on.

### 6. Track what's resolved, announce transitions

When you finish a major area of the decision tree, briefly say so before moving to the next:

> OK — data model is settled. Moving on to the API contract.

This lets the user know where you are in the interview and signals that you're being systematic, not random.

## When to stop

When all major branches are resolved, or the user calls it done, write a **Shared Understanding** section:

- A tight, concrete list of the decisions made
- Specific enough that an engineer could read it and implement without asking follow-ups
- Flag any explicitly deferred items as open questions

Don't stop early just because the user says "sounds good" to one question. Keep going until the whole tree is covered.

## What good questions look like

Good questions are *specific*, not generic:
- "What's the timeout for the downstream call, and what do we return when it hits?" — not "what about failures?"
- "Should a user with read-only permission still appear in list results?" — not "what about permissions?"
- "If the client sends the same request twice, does the second one fail or succeed silently?" — not "is this idempotent?"

Good questions *respect dependencies*:
- Agree on sync vs. async before asking about queue names or worker counts
- Agree on the data model before asking about the API response shape
- Agree on user-facing behavior before designing the error messages
