---
name: etymology-lookup
description: >
  Fetch authoritative etymology BEFORE claiming any word origin or morphological
  breakdown. Use whenever the user asks about word roots, etymology, morpheme
  decomposition, or "where does this word come from" — phrases like "字根", "詞源",
  "怎麼拆", "為什麼這樣拼", "root of X", "etymology of", "morphology", "where does
  X come from", "how is X built". ALSO trigger on pushback after you stated an
  etymology — "你怎麼知道", "有證據嗎", "權威來源", "any source for that", "are
  you sure", "show me the source". Critical when filling the `## Root` section
  in /home/fenrir/code/language/english/vocabulary/*.md files. Without this
  skill, Claude invents plausible-sounding morphological mechanisms (vowel
  elision, sound shifts, prefix reductions) that aren't in any source — this
  skill forces source-first WebFetch from Etymonline + Wiktionary with inline
  URL citations.
---

# Etymology Lookup

When you talk about a word's origin, **fetch first, claim second**. Your morphological intuitions sound right but get details wrong, and the user can't tell which parts you made up. The cost of fetching is one tool call; the cost of being wrong is the user losing trust in everything else you say about language.

## The non-negotiable rule

If you're going to write any of the following, you must have a source URL open in this turn:

- "from Latin/Greek/Old English/PIE X + Y"
- "the prefix X means Y"
- "the root is Z" / "shares the root with..."
- A morpheme breakdown (e.g. `amb-` + `ig-` + `-uous`)
- A claim about how the spelling evolved (vowel weakening, elision, assimilation, apophony, ablaut, syncope)
- A literal/original meaning ("literally meant 'to drive both ways'")

If you can't find a source for a claim, **say so out loud**. Do not paper over a gap with a plausible guess — the user has been burned by exactly this.

## Lookup order

### 1. Etymonline (primary)

```
https://www.etymonline.com/word/<lemma>
```

- Lemma = lowercase base form (verb infinitive, singular noun, positive adjective)
- Multi-word entries use a hyphen: `https://www.etymonline.com/word/put-off`
- Use the `WebFetch` tool. Don't web-search — go directly to the URL pattern.

### 2. Wiktionary (fallback)

```
https://en.wiktionary.org/wiki/<lemma>
```

Use when:
- Etymonline returns 404 or has no entry
- Etymonline's entry is too thin
- You need PIE roots, cognates in other languages, or non-Indo-European etymology
- The word is non-English (Chinese characters, Japanese, etc.)

Look at the `Etymology` section.

### 3. No source found

Say it explicitly:

> "I couldn't find this on Etymonline or Wiktionary. I won't guess at the etymology — if you need certainty, OED or American Heritage Dictionary will have it."

## What to extract — and what NOT to

### Copy from the source:
- The proximate parent ("from Latin `ambiguus`")
- The deeper chain if given ("from `ambigere`, from `ambi-` + `agere`")
- Glosses the source provides ("'to drive, lead, act'")
- The PIE root if cited ("PIE `*ag-` 'to drive'")

### Do NOT copy or invent:
- **Spelling-mechanism explanations** — vowel weakening, elision, assimilation, syncope. Even if real Latin morphology, don't claim a specific rule applies unless the source says so.
- "Why" the spelling looks the way it does
- Sound-change rules
- Cognates you "remember" but the source doesn't list

If the user asks "why is `ambiguous` spelled with one `i`?" and the source doesn't address it, say:

> "Etymonline gives the etymology as `ambi-` + `agere` but doesn't explain the spelling mechanism. The reduction from `ambi + ag-` to `ambig-` involves Latin vowel-weakening rules that go beyond what the source covers — I'd be guessing if I tried to be more specific."

## Citation format

Cite the URL **inline**, the first time you state an etymology in a turn.

**Acceptable styles:**

> From Etymonline: Latin `ambiguus`, from `ambigere` "to wander," from `ambi-` "about" + `agere` "drive, lead, act." (https://www.etymonline.com/word/ambiguous)

> Latin `ambiguus` ← `ambigere` ("to wander") ← `ambi-` ("about") + `agere` ("drive, lead, act"). Source: https://www.etymonline.com/word/ambiguous

When citing both Etymonline and Wiktionary, list both URLs.

## Speaking honestly about uncertainty

When you go beyond the source, label it. Phrases that work:

- "Etymonline says X. The mechanism behind that is my reading, not in the source."
- "I'm extrapolating beyond the source here:"
- "The source stops at X + Y; how those merged in spelling isn't covered."
- "This next part is intuition, not from the citation."

The user has explicitly asked for this distinction. Erring on the side of stopping at what the source says is the right error to make.

## When working in /home/fenrir/code/language/english

The `## Root` section in `vocabulary/<lemma>.md` files MUST be source-backed. When filling it:

1. Fetch the Etymonline page for the lemma.
2. Quote/paraphrase only what's there.
3. Stylistic glosses (literal meaning) only if the source provides them.
4. Per the project's CLAUDE.md, omit `## Root` for opaque native compounds and most phrasal verbs where no shared root meaningfully connects other English words.

For `## Word Family`, only list words confirmed (by Etymonline or Wiktionary) to share the root. Don't list `ambient` as a cognate of `ambiguous` just because both sound `ambi-`-ish — verify each one. (In this case both *are* from `ambi-`, but you should check.)

## Other languages

- **English / Latin / Greek / French loans / PIE**: Etymonline → Wiktionary
- **Chinese characters (漢字)**: Wiktionary character entries (e.g. `https://en.wiktionary.org/wiki/漢`) cite Shuowen Jiezi and modern reconstructions
- **Japanese**: Wiktionary entries cover native (和語) and Sino-Japanese (漢語) etymology
- **Other**: Default to Wiktionary

## Worked example — what NOT to do, and what to do

**User:** "what's the root of `ambiguous`?"

### Wrong (what happened, and what triggered this skill):

> From `ambi-` "both" + `agere` "drive". The `i` of `ambi-` and the `a` of `agere` underwent vowel elision to give `ambig-`.

Problems: invented "vowel elision" rule with no citation. Sounds authoritative. User can't tell it's a guess.

### Right:

> [Fetch https://www.etymonline.com/word/ambiguous]
>
> Etymonline: Latin `ambiguus` "having double meaning, shifting, doubtful," from `ambigere` "to dispute about," literally "to wander," from `ambi-` "about" + `agere` "to drive, lead, act."
>
> Source: https://www.etymonline.com/word/ambiguous

If the user follows up with "why is it spelled `ambiguous` and not `ambiiguous`?":

> Etymonline doesn't address the spelling mechanism — it stops at `ambi-` + `agere`. The merger to `ambig-` involves Latin vowel rules I can't cite a specific source for, so I won't claim a particular mechanism. If you want the precise morphology, OED or a Latin grammar would be the place.

## Quick checklist before you hit Send

- [ ] Did I fetch a source this turn (not "I remember from training")?
- [ ] Did I cite the URL inline?
- [ ] Did I avoid claiming any sound-change / morphology rule the source doesn't state?
- [ ] If I extrapolated beyond the source, did I flag it as my reading?
