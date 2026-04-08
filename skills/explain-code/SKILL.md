---
name: explain-code
description: Explains code with visual diagrams and analogies. Use when explaining how code works, teaching about a codebase, or when the user asks "how does this work?" Also use when the user asks to explain an API endpoint, a feature module, a class, or a function — even if they just paste a file path or an endpoint URL.
---

When explaining code, structure your explanation with these sections:

## 1. Start with an analogy

Compare the code to something from everyday life. The analogy should cover the **core complexity** of the code, not just the high-level concept. If the interesting part is "7 tables are joined together", the analogy should make the reader feel *why* that many sources are needed — not just that "a query happens".

If the analogy uses a specific number (e.g. "seven sources"), make sure the diagram and walkthrough use the same number for the same concept — or explicitly note when they count differently (e.g. "7 JOIN clauses across 6 distinct tables, with `user_staff` joined twice").

## 2. Define domain terms before using them

Before the walkthrough, include a short **Key Domain Terms** block (3-8 entries) that defines every non-obvious term in plain language. This is especially important for:

- **Industry jargon** the reader may not know (e.g. casino terms like 靴/Shoe, 洗碼量/Wash Code)
- **Code-translated terms** that look like plain language but carry specific technical meaning (e.g. `mainResult` → "主結果" — define what it actually refers to)
- **Abbreviated identifiers** in the codebase (e.g. `PAS_PLAYER_TRACKING_Q` — what does `PAS` stand for? what does `_Q` mean?)
- **Near-suffix pairs**: When two terms differ by only a suffix (e.g. `shuffle` vs `shuffler`, `deal` vs `dealer`, `encode` vs `encoder`), define **both** in the table — even if one seems obvious. Readers skim term tables and a one-character difference is easy to miss. Explicitly state how the two concepts relate (e.g. "shuffler is the person; shuffle is the method they use").

The test: if a PM who has never seen the codebase reads the term, would they understand it without guessing? If not, define it.

## 3. Draw a diagram

Use ASCII art to show the flow, structure, or relationships. Diagrams must be **faithful to the code**:

- In data-flow or JOIN diagrams, every arrow/line must reflect the actual join key or call direction. Don't let visual layout imply false relationships (e.g. if table A and table B both join from the main table, draw both lines from the main table — not from each other).
- Label relationships where ambiguity is possible (e.g. `bd.user_id = p.id`).

## 4. Walk through the code

Explain step-by-step what happens, following the request lifecycle. Three rules to keep the walkthrough trustworthy:

### Source-faithful references

When you cite a number, constant, annotation, or identifier from the code, **verify it matches the source exactly**. Common pitfalls:

- **Error codes**: Use the actual literal from the source (e.g. `20251218222650L`), not a different number from elsewhere. If it's a named constant (e.g. `BizException.BAD_REQUEST`), show both the constant name and its resolved value if known.
- **Annotations & decorators**: If the code has `@Transactional(readOnly = true)` or `@Permission(...)`, mention them and explain what they do. Don't say "the framework handles it" without pointing to the specific mechanism (which class, which method, which annotation).
- **Line numbers**: Reference `FileName.java:lineNumber` so the reader can jump to the source.

### Read-or-mark rule

If you describe what a function or method does, you must either **read its source and cite file:line**, or **mark the description as `(inferred)`**. This matters because inference from a function signature or naming pattern can be wrong — the function might do extra work (logging, permission checks, exception wrapping) that the name doesn't reveal. An `(inferred)` marker tells the reader "I haven't verified this; check if it matters to you."

Example:
> The `wrap()` helper deserializes the request body and delegates to `doAction`. *(inferred from usage pattern — source not read)*

### Flag unreachable or defensive code paths

When explaining validation or error-handling code, trace whether the check can actually be triggered via the normal entry point. If an upstream layer (e.g. a framework `wrap()` method, JSON deserializer, or middleware) already handles the condition before it reaches the code you're explaining, note that the check is defensive:

> "This null check exists in the service, but for HTTP requests, Jackson throws on empty body before the request reaches this point — making this defensive code that only triggers if the service is called programmatically."

This matters because readers use explanations to build mental models of what *actually happens* at runtime. Presenting dead-code checks at the same level as live checks creates a false model.

### Flag caveats from code comments

Read the comments and annotations in the source code carefully. If a field, parameter, or feature is:

- **Reserved / not yet active** (e.g. a comment says "目前沒有, 先附上")
- **Deprecated or scheduled for removal**
- **Conditionally populated** (e.g. only non-null when another field has a certain value)

...flag it explicitly in your explanation. Don't present placeholder fields at the same level as active ones — the reader will assume everything is live data.

When a comment is **ambiguous about history or evolution** (e.g. `(原預洗牌法) 撲克牌花色` — does "原" mean the field was repurposed, or is it just an alternative name?), **state exactly what the comment says and note the ambiguity**. Don't speculate about what happened. Speculation reads as fact to a reader who trusts the explanation.

Good: "The comment labels this field `(原預洗牌法) 撲克牌花色`. Whether '原' means the field was repurposed or is simply an alias is unclear from the code alone."

Bad: "This field used to store the shuffling technique and was later reinterpreted as card color."

However, **do look for corroborating patterns** before declaring something ambiguous. If the same prefix or comment pattern appears on multiple related fields, note the pattern — that's evidence, not speculation. For example:

Good: "The `(原...)` prefix appears on both `color` and `shuffler` but not on `shuffle`, suggesting these fields were decomposed from a single earlier concept. This is inferred from comment patterns — no migration history was reviewed."

The distinction: speculation invents history ("this field used to store X"); pattern-noting describes what's visible ("these three comments share a prefix, suggesting a relationship").

## 5. Highlight a gotcha

What's a common mistake, misconception, or subtle behavior? Good gotchas come from:

- Architectural decisions that look like bugs (e.g. duplicated record types across layers)
- NULL behavior in SQL (e.g. `CONCAT` treating NULL differently across databases)
- Annotations that silently constrain what you can do (e.g. read-only transactions blocking writes)

When a gotcha involves a **cross-database or cross-language comparison** (e.g. "PostgreSQL does X, unlike MySQL"), verify the comparison is accurate, or mark it explicitly: *(based on memory — recommend verifying)*. A wrong comparison is worse than no comparison, because the reader now has a confident-sounding but incorrect mental model.

## 6. Verification pass

After writing the full explanation, do a final check before presenting it. The writing phase and the verification phase use different cognitive modes — synthesis vs. auditing — so this step catches things that slip through during writing.

Include this section in the output with pass/fail results for each item. Readers trust an explanation more when they can see it was self-audited — and any issues found here (like a source/test discrepancy) become valuable findings in their own right.

Checklist:

- [ ] **Numbers**: Every error code, constant, or literal cited in the explanation — open the source file and confirm the value matches. Pay special attention to error codes, which often look similar.
- [ ] **Source vs. test consistency**: If you read both implementation and test files, cross-check error codes and key constants between them. If they disagree, flag it as a caveat (the reader will want to know).
- [ ] **No unattributed framework claims**: Search the explanation for phrases like "the framework handles", "is checked before", "is automatically". Each must have a file:line citation or an `(inferred)` marker.
- [ ] **No unverified comparisons**: Search for "unlike", "differs from", "in contrast to", "compared to". Each cross-system comparison must be accurate or marked as unverified.
- [ ] **Term completeness**: Scan the explanation for any term pairs that differ by a suffix and confirm both are in the Key Domain Terms table.

### Surface findings inline

The verification pass is an audit — it catches things. But if findings stay only in this section, readers treat them as footnotes. After completing the checklist:

- For each source-vs-test discrepancy or error code mismatch found, go back to the walkthrough step where that code/constant first appears and add an inline warning (e.g. "⚠️ The test expects X but the implementation uses Y — see Verification Pass").
- The verification pass keeps the full analysis; the walkthrough gets a visible flag so readers encounter it in context.

---

Keep explanations conversational. For complex concepts, use multiple analogies.