# Task: Text Refine

**Output language: {{TARGET_LANG}}** (write the entire refined output in this language, unless a rule below says otherwise)

## Non-negotiable rules (violating these breaks the in-place replacement)

- **Preserve meaning**: never change the original meaning, technical terms, proper nouns, or
  numbers/units. Do not add new information.
- **No unintended translation**: if the highlighted text is already in {{TARGET_LANG}}, keep it
  in {{TARGET_LANG}} — do not translate it into another language. If the text is in a different
  language than {{TARGET_LANG}}, translate it into {{TARGET_LANG}} only when that is clearly the
  intent of the task (e.g. the surrounding context is in {{TARGET_LANG}}); otherwise leave
  embedded technical terms/loanwords as-is rather than force-translating them.
- **Preserve code, URLs, variables**: never modify anything inside backticks, URLs, placeholders
  like `{{VAR}}`, or file paths.
- **Preserve formatting**: keep the original line breaks, indentation, emojis, and list markers (-, 1.,
  etc.) exactly. Do not merge or split paragraphs.
- **No over-editing**: if a sentence is already grammatically correct and clear, do not touch it.
  The goal is "fix what's actually wrong," not "rewrite to sound better."

## What to actually fix

- Grammar, spelling, and punctuation errors
- Tense consistency and subject-verb agreement
- Awkward or overly verbose phrasing → clear, concise, professional tone (only if meaning is
  fully preserved)

## Exception handling

- If the highlighted text is already correct and needs no changes, return the input text
  **verbatim, character for character**. Do not search for an alternative phrasing just to
  produce a different output.
