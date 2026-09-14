# Auditing shadow rates in a shared context

Companion to Rule 20 of the `rspec-quality` skill. Use it when deciding
whether a `let` in a shared context (`with default_creates` here) is
earning its keep or is net negative.

When a shared context contains many lets, some may be earning their
keep and others may be net negative. Diagnose with a shadow-rate
audit: for each let, count how many spec files use the name and how
many of those declare a local `let` overriding it.

**Heuristic for removal:** when a let has ≥50% shadow rate *among real
value-users*, the shared default is more confusion than convenience.
Remove it from the shared context — the remaining callers can each
declare a local `let`. If the shared default were genuinely useful,
those callers wouldn't be shadowing.

**Count real value references, not raw word matches.** A naive
`grep -l "\bNAME\b" spec/` overcounts callers because the word `NAME`
appears in many contexts that aren't references to the let value:

- Factory symbols (`create(:NAME, ...)`)
- Strings inside test descriptions (`it "shows the NAME"`)
- CSS class and ID selectors (`.NAME-row`, `#NAME-list`)
- Compound identifiers (`NAME_id`, `something_NAME`)
- Method calls on other objects (`other.NAME`)
- Predicate methods (`record.NAME?`)

In practice this can inflate the apparent caller count by 30–100%.
Letting it through tells you the shadow rate is low (because real
users hide in a large denominator) when the shared default is in fact
heavily customised.

**Use `ast-grep` for AST-aware identifier matching.** It treats
`NAME` as a Ruby identifier and distinguishes it from the patterns
above:

```bash
# Files where NAME is referenced as a Ruby identifier (not just a word)
ast-grep --pattern 'NAME' --lang ruby spec/ \
  | grep -oE '^[^:]+_spec\.rb' | sort -u
```

Combine with `grep` for the shadow set to compute the true shadow
rate:

```bash
# Shadow files
grep -rl "let!\?(:NAME)" spec/ --include="*_spec.rb"

# Subtract shadows from real users to find files that use the default
```

**Beware partial shadowing.** A file that declares `let(:NAME)` in one
nested context but uses the default in other contexts is *not* a clean
shadower — removing from the shared context will break the
non-shadowing contexts. After removal, run the suite; failures of the
form `undefined local variable or method 'NAME'` point at files that
need a top-level local `let`.
