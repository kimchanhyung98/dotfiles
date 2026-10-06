# AGENTS.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:

1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes

## 6. Jev MCP

Inspect the available Jev MCP tools and their descriptions, then choose and use the tools appropriate for the task. Cross-check the results against the actual code, evidence, and tests.

## 7. Documentation Writing

When writing or editing documentation, aim for "80% of the way to ASD-STE100 Simplified Technical English," as suggested in [Karpathy's post](https://x.com/karpathy/status/2105819303471976479). Treat this as a readability goal, not a measured compliance score.

- Write documentation in Korean. Prioritize natural Korean phrasing and technical accuracy.
- Use short, direct sentences with clear subjects and active verbs. Keep one idea per sentence and one topic per paragraph.
- Use the same term for the same concept. Preserve technical terms and define them when needed.
- Put one action in each procedural step. State prerequisites and conditions before the action.
- Preserve facts, numbers, units, conditions, exceptions, and uncertainty. Do not remove meaning to shorten the text.
- Prefer technical accuracy and natural phrasing over strict dictionary or sentence-length limits.
- For Korean documentation, apply these clarity principles using natural Korean grammar. Do not impose English vocabulary or word-count rules.
