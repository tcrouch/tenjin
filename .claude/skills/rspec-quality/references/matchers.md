# Matcher catalogue

Companion to Rule 15 of the `rspec-quality` skill: the full before/after
catalogue behind the quick-reference table. Choose the matcher that most
precisely expresses the intent. Vague matchers produce vague failure
messages.

**Boolean and nil values** — use predicate matchers, not `eq`:

```ruby
# Before
expect(user.admin?).to eq(true)
expect(result).to eq(false)
expect(record).to eq(nil)

# After
expect(user.admin?).to be true
expect(result).to be false
expect(record).to be_nil
```

`be_truthy` / `be_falsy` are correct only when the value is not strictly
`true`/`false` — e.g. when testing that an ActiveRecord object exists vs. is
`nil`. Don't use them as loose replacements for `be true` / `be false`.

**Empty collections** — `be_empty` is clearer than comparing to `[]` or `0`:

```ruby
# Before
expect(user.homeworks).to eq([])
expect(page.all(".row").count).to eq(0)

# After
expect(user.homeworks).to be_empty
expect(page).to have_css(".row", count: 0)  # or have_no_css(".row")
```

**Array contents** — `include`, `contain_exactly`, and `match_array` have
distinct semantics; pick the right one:

| Matcher | Checks | Order matters? |
|---|---|---|
| `include(*items)` | array contains *at least* these items | No |
| `contain_exactly(*items)` | array contains *exactly* these items | No |
| `match_array(array)` | alias for `contain_exactly` with a single array arg | No |

```ruby
# include is correct when subset membership is the intent
expect(subjects).to include("Maths")  # passes with ["Maths", "Science", "History"]

# Use contain_exactly when the full set is what matters
expect(subjects).to contain_exactly("Maths", "Science")  # fails if extra items exist

# match_array is an alias for contain_exactly with a single array argument
expect(subjects).to match_array(["Maths", "Science"])
# prefer contain_exactly — same semantics, splat style is more idiomatic
expect(subjects).to contain_exactly("Maths", "Science")
```

When you see `include` in a spec, ask: should this test pass if extra items exist?
If yes, `include` is correct. If no, switch to `contain_exactly`.

**`change` compound matchers** — use `by` for deltas, `from/to` when both
boundary values matter:

```ruby
# by — use when only the delta matters; starting value is not under test
expect { answer.save }.to change { student.points }.by(10)

# from/to — use when both boundary values are meaningful; by(10) would pass
# even if points started at 100 rather than 0
expect { user.disable! }.to change { user.disabled }.from(false).to(true)
expect { award_bonus }.to change { student.points }.from(0).to(10)
```

**Predicate matchers** — RSpec generates `be_<predicate>` for any `?` method.
Prefer these over calling the predicate and asserting the boolean:

```ruby
# Before
expect(record.valid?).to be true
expect(user.admin?).to be false
expect(name.present?).to be true
expect(list.empty?).to be true

# After
expect(record).to be_valid
expect(user).not_to be_admin
expect(name).to be_present
expect(list).to be_empty
```

This applies to any predicate: `be_active`, `be_disabled`, `be_completed`,
`be_blank`, `be_published`, etc. The failure message is also clearer —
`expected user to be admin` rather than `expected false to be true`.

**`have_attributes`** — when asserting multiple attributes on the same object,
use one `have_attributes` instead of chained `eq` expectations:

```ruby
# Before
expect(user.name).to eq("Tom")
expect(user.role).to eq("student")
expect(user.school).to eq(school)

# After
expect(user).to have_attributes(name: "Tom", role: "student", school: school)
```

This produces a single, readable failure that lists all mismatched attributes
at once rather than stopping at the first.

**Consolidate fragmented state assertions** — when several `it` blocks all
assert different properties of the same object or collection after the same
action, collapse them into a single example using `contain_exactly` with
`have_attributes` (for collections) or `have_attributes` alone (for a single
object). Three or more separate tests that each call the same setup action and
check one property of the resulting state are a signal to consolidate:

```ruby
# Before — four tests, each re-running the same setup
it "creates a false answer" do
  question.update_attribute(:question_type, "boolean")
  expect(question.reload.answers.first.text).to eq("False")
end
it "creates a true answer" do
  question.update_attribute(:question_type, "boolean")
  expect(question.reload.answers.second.text).to eq("True")
end
it "sets answers as incorrect" do
  question.update_attribute(:question_type, "boolean")
  expect(question.reload.answers.first.correct).to be(false)
end

# After — one test covering all properties, order-independent
before { question.update_attribute(:question_type, "boolean") }

it "replaces existing answers with boolean answer choices" do
  expect(question.reload.answers).to contain_exactly(
    have_attributes(text: "False", correct: false),
    have_attributes(text: "True", correct: false)
  )
end
```

`contain_exactly` asserts the exact set of elements regardless of order;
`have_attributes` asserts multiple properties of each element at once. Together
they replace ordering-dependent `first`/`second` index lookups and cover both
content and attributes in a single readable assertion.

**`be_within`** — never use `eq` to compare floats or decimals; floating-point
arithmetic makes exact equality unreliable:

```ruby
# Before — can fail due to floating-point precision
expect(score).to eq(33.33)

# After — tolerance-based comparison
expect(score).to be_within(0.01).of(33.33)
```

**`all` matcher** — when every element of a collection must satisfy a
condition, use `all` rather than asserting on a single representative element
or iterating manually:

```ruby
# Before — only checks one element; doesn't prove the whole collection
expect(users.first).to be_active
# Before — manual iteration, verbose
users.each { |u| expect(u).to be_active }

# After
expect(users).to all(be_active)
expect(homeworks).to all(have_attributes(classroom: classroom))
```

**`raise_error` specificity** — always name the error class. Bare
`raise_error` catches everything, including `NoMethodError` and `NameError`,
so it can pass on bugs rather than the intended exception:

```ruby
# Before — too broad, will pass on any error including typos
expect { service.call }.to raise_error

# After — asserts the specific error type
expect { service.call }.to raise_error(ActiveRecord::RecordNotFound)

# Include the message when it distinguishes error cases
expect { service.call }.to raise_error(ArgumentError, /invalid topic/)
```

**Capybara text vs CSS** — use `have_text` when asserting on visible text
content; `have_css` when asserting on element structure or non-visible
attributes. Don't use `have_css` with a bare text string, and don't use
`have_text` to assert on CSS selectors or class names:

```ruby
# Before — checking CSS structure with have_text
expect(page).to have_text(".leaderboard-row")

# After
expect(page).to have_css(".leaderboard-row")

# Before — asserting visible text with have_css
expect(page).to have_css("Tom")

# After
expect(page).to have_text("Tom")
```
