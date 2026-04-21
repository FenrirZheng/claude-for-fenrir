---
name: english-polish
description: >
  Polish user-supplied Chinese, Chinglish, or awkward-but-grammatical English
  into natural, idiomatic English with register options (casual / neutral /
  formal). Trigger on any message that mixes Chinese characters with English
  inside one sentence ("I 想 finish this by 明天"), pure Chinese the user
  clearly wants rendered in English, or explicit polish requests — "潤色",
  "改得自然一點", "怎麼講比較好", "幫我改", "這樣講對嗎", "make this sound
  natural", "better way to say this", "more idiomatic", "sounds off", "does
  this sound native", "rewrite this". Do NOT trigger for pure English with
  actual grammar errors ("I very like coffee") — that's a Mode B correction,
  not a polish. Do NOT trigger for vocabulary lookups ("how do I say 拖延 in
  English") — that's Mode A. Tiebreaker when both grammar-correction and
  polish could apply: if any CJK character is present, prefer polish; if the
  English is grammatical but clunky, prefer polish.
---

# English Polish

Rewrite the user's Chinese, Chinglish, or clunky English into natural idiomatic English. The output is always **three register-labelled variants plus a short "what I changed" note** — never a single "corrected" sentence. This is fluency work, not grammar policing.

## When this skill applies

The user has said something they want to express in English and it either:

1. **Contains CJK characters** — any Chinese character anywhere in the message. Examples: "我今天 feel 有點 tired", "幫我寫一封道歉信給客戶", "想講『我盡量配合』用英文怎麼講".
2. **Is pure English but sounds off** — grammatically defensible yet awkward, over-literal from Chinese, or wrong register. Examples: "I very like this plan and want to proceed it quickly", "Please borrow me your pen", "I will try my best to cooperate with you".
3. **Is an explicit polish request** — "潤色", "改得自然一點", "怎麼講比較好", "make this more natural", "rewrite this so it sounds native", "more idiomatic version".

## When this skill does NOT apply

- **Pure-English sentence with a clear grammar error and no CJK** → that's **Mode B** (correction + log to `mistakes/YYYY-MM.md`). Do not fire this skill; let Mode B handle it.
- **"How do I say X in English?" / single-word lookup** → that's **Mode A** (vocabulary entry + write to `vocabulary/<lemma>.md`). Do not fire this skill. If during a polish the user asks about a single word, *offer* a Mode A handoff but do not auto-trigger it.
- **Weekly review / pattern summary requests** → that's **Mode C**.

### Tiebreakers

- Any CJK character in the input → prefer polish over grammar correction.
- Input is grammatical but unnatural → prefer polish over grammar correction.
- Input is a single word or phrase asking "what's the English for…" → prefer Mode A over polish.

## Output format — the four mandatory parts

Reply in this exact order. Markdown headings are optional; the structure is what matters.

### 1. Intent (one line)

One short sentence interpreting what the user is trying to express. This is your comprehension check — the user will correct you if you misread. Write it in the same language the user wrote in (English if they wrote English, Chinese if they wrote Chinese).

Example: `Intent: you want to tell a colleague you're behind on replies because work has been hectic.`

### 2. Polished versions (2–3, register-labelled)

Exactly 2 or 3 variants, each on its own line, prefixed with a register label and a colon. Labels are lowercase: `casual:`, `neutral:`, `formal:`. Pick which labels to include based on what actually fits the situation — you don't always need all three. Do **not** separate variants with ` / ` the way Mode B corrections are separated; polish variants are substantively different registers, not minor alternatives.

Example:
```
casual:   Sorry for the slow reply — been swamped this week.
neutral:  Apologies for the late response; it's been a busy week on my end.
formal:   Please forgive the delayed reply; I've been exceptionally occupied this week.
```

### 3. Key improvements (2–4 bullets)

What changed and why. Focus on **patterns a learner can reuse**, not per-word substitutions. Good bullets name the underlying mechanism:

- "`想要 finish` → `want to finish` — English takes the bare infinitive after *want*, no extra modal."
- "`very like` → `really like` / `like … a lot` — *very* modifies adjectives/adverbs, not verbs."
- "`proceed it` → `push ahead with it` / `move forward on it` — *proceed* is intransitive in this sense; English uses a particle verb."

Keep it to 2–4 bullets. If you find yourself writing a fifth, you're explaining too much — trim.

### 4. Optional follow-up (at most one line)

If a single word or collocation inside your polished version is clearly worth a full vocabulary entry, end with a one-line offer:

> Want me to add `swamped` to vocabulary? (Mode A lookup)

Do **not** auto-trigger Mode A. The offer is an invitation; wait for the user to confirm. Skip this line entirely if no single word stands out — don't invent a reason to offer.

## Register rubric — make the variants actually different

`casual` / `neutral` / `formal` should feel like different people wrote them, not the same sentence with one word swapped. Rough guide:

| Axis | casual | neutral | formal |
|---|---|---|---|
| Contractions | yes, freely | some | avoid |
| Hedging | "kinda", "sort of" | "a bit", "somewhat" | "somewhat", "to some extent" |
| Idioms / phrasal verbs | welcome | used sparingly | avoid most |
| Word origin | Anglo-Saxon (get, put, keep) | mixed | Latinate (obtain, submit, retain) |
| Apologies / thanks | "sorry!" / "thanks!" | "apologies" / "thank you" | "please accept my apologies" / "I am grateful" |
| Subject drop | sometimes ("Been busy.") | rarely | never |

If two variants look 80% identical, collapse them into one and drop a register — three near-identical variants are worse than two genuinely different ones.

## File writes — opt-in only

**Default: write nothing.** This skill produces output in chat; it does not modify files.

**The one exception:** if the user explicitly asks to save — phrases like "記下來", "save this", "log this one", "save the neutral one" — AND the current working directory is `/home/fenrir/code/language/english` (check with `pwd` if unsure), then append the user's chosen variant to `sentences/YYYY-MM.md` using the exact format from that repo's CLAUDE.md:

```
- [polish] The **polished** sentence the user picked.
```

Rules for the append:
- Monthly file is **append-only** — never rewrite existing content. If the file does not exist, create it with a `# YYYY-MM` header line first.
- Date uses UTC+8.
- Tag is literally `[polish]`, not the lemma.
- Bold the most-learnable word or phrase with `**…**` (the flashcards program extracts the bolded span).
- Never write to `mistakes/`, `vocabulary/`, or anywhere else from this skill — those belong to Mode A / Mode B.

**If the user asks to save but cwd is not the english repo**, say so plainly and skip the write:

> I can't save this outside the english-learning repo — the `sentences/` folder only exists there. Want to copy it yourself, or shall I just leave it in chat?

## Worked examples

### Example 1 — pure Chinese

**Input:** `我最近很忙，沒空回訊息`

**Reply:**
```
Intent: you want to apologize to someone for not replying — you've been busy.

casual:   Sorry, been swamped lately — haven't had a chance to get back to people.
neutral:  Apologies for going quiet; things have been hectic and I haven't had time to reply.
formal:   Please forgive the delayed response; I have been exceptionally busy and unable to attend to messages.

Key improvements:
- `沒空回訊息` → `haven't had a chance to get back` — idiomatic English prefers *get back to (someone)* over literal *reply to messages*.
- `很忙` opens up in register: `swamped` (casual) / `hectic` (neutral) / `exceptionally busy` (formal). Picking one pins the whole sentence's tone.
- Casual English often drops the subject pronoun in reply-style messages ("been swamped" vs. "I've been swamped") — common in chat, unusual in email.

Want me to add `swamped` to vocabulary? (Mode A lookup)
```

### Example 2 — Chinglish

**Input:** `I 想要 finish this by 明天 but 可能 需要 your help`

**Reply:**
```
Intent: you want to finish something by tomorrow but may need help.

casual:   I want to wrap this up by tomorrow, but I might need a hand.
neutral:  I'd like to finish this by tomorrow, but I may need your help.
formal:   I aim to complete this by tomorrow; however, I may require your assistance.

Key improvements:
- `想要 finish` → `want to finish` / `'d like to finish` — English takes a bare infinitive after *want*, and `'d like to` is a softer neutral variant.
- `可能 需要` → `might need` (casual) / `may need` (neutral) / `may require` (formal) — the modal alone carries the hedging; no need for a separate *maybe*.
- `wrap this up` (casual) vs. `complete this` (formal) demonstrates the Anglo-Saxon ↔ Latinate register shift at the verb level.
```

### Example 3 — clunky but grammatical English

**Input:** `I very like this plan and want to proceed it quickly.`

**Reply:**
```
Intent: you like the plan and want to move on it quickly.

casual:   I really like this plan — let's get moving on it.
neutral:  I like this plan a lot and would like to move forward with it quickly.
formal:   I strongly support this plan and would like to proceed with it without delay.

Key improvements:
- `very like` → `really like` / `like … a lot` — *very* modifies adjectives and adverbs, not verbs. This is a very common L1-Chinese carryover.
- `proceed it` → `proceed with it` / `move forward with it` — *proceed* in this sense is intransitive; it takes a preposition, not a direct object.
- `quickly` → `without delay` in the formal register — adverb-of-manner upgrade matches the Latinate verb.

Want me to add `proceed with` to vocabulary? (Mode A lookup — it's a high-value collocation.)
```

Note how Example 3 has no CJK but still triggers this skill: the English is grammatical-ish but unnatural, and *very like* / *proceed it* are exactly the kind of issues polish should catch rather than route to Mode B's log. Mode B would flag "I very like coffee" as a grammar error (appropriate — short, clearly wrong); polish owns the longer, register-sensitive cleanup.

## Pre-send checklist

Before you hit Send, confirm:

- [ ] Exactly **one** Intent line.
- [ ] **2 or 3** polished versions, each on its own line, each with a register label (`casual:` / `neutral:` / `formal:`).
- [ ] Variants feel meaningfully different — not the same sentence with one synonym swapped.
- [ ] **2 to 4** improvement bullets, each naming a reusable pattern (not just a word swap).
- [ ] Followed-up Mode A offer only if a genuinely useful word/phrase surfaced — otherwise omit.
- [ ] No file writes unless the user explicitly said "save / log / 記下來" AND cwd is the english repo.
- [ ] If a write happened: exactly one line appended to `sentences/YYYY-MM.md` with `[polish]` tag and `**bold**` target span.
