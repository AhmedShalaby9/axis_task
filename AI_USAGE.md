# AI Usage Log

**Tools**
- Claude Code — implementation and scaffolding

**Approach**
I used the coding agent for structure, and reviewed its
output against the assessment requirements before accepting anything

---

## 2026-08-28 — Architecture proposal

**Prompt**
> Flutter app: currency exchange tracker. Base EGP, 5 targets
> (USD, EUR, GBP, SAR, JPY). Two screens: rates list, and a detail screen
> with a 7-day line chart. Needs offline caching.
> Propose a clean architecture folder structure with BLoC...

**Returned**
A two-feature structure (`exchange_rates`, `rate_detail`), each with its
own full data/domain/presentation stack. Exception/Failure split, abstract
UseCase base, per-page BlocProvider scoping.

**Decision:** Edited ✏️

**Why**
The exception/failure separation and the data-flow contract were sound and
I kept them. But splitting into two features duplicated the data layer for
no reason — both hit the same endpoint (`egp.json`) with the same model.
The requirement is domain-driven *BLoC* separation, not duplicated
repositories. Merged to one `currency` feature with two BLoCs.

Four other gaps I sent back:
- Daily change needs two calls (today + yesterday); the proposal had a
  single `get_exchange_rates` use case with no orchestration for it.
- `NetworkInfo` was a one-shot bool check, but Module 3 requires
  auto-refresh on reconnect — that needs a connectivity Stream.
- The rate inversion (`1 ÷ egp.usd`) wasn't assigned to any layer.
  It's the core business rule of the app.
- No DI container at all.

Ran a second pass with these as explicit constraints.


**Follow-up result**

Second pass merged the data layer into a single `currency` feature with
two page-scoped BLoCs, added a `get_it` DI container, moved the inversion
into the repository's model→entity mapping, and made `NetworkInfo` expose
a connectivity stream.

I accepted the inversion placement — the reasoning was sound: the
datasource should represent the API faithfully, and putting it in the
mapper means one line changes if the API direction ever flips.

Still sent back a third round on:
- **Call count.** `GetDailyChange` took a single currency code, so the list
  screen would have called it five times — 10 requests for data that fits
  in 2. One response already contains all five currencies.
- **Missing timestamps.** No entity carried a date or a cache/network
  origin flag, but Module 2 requires "date of last update" and Module 3
  requires a "last updated" indicator for offline data.
- **Color semantics.** Green means EGP *strengthening*, so a falling
  USD/EGP rate is green — the opposite of the usual convention. Left
  unspecified, this would have been decided ad-hoc inside a widget.