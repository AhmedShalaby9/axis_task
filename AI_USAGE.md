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


---

**Third round**

Consolidated to a single `GetAllRatesWithChange` use case (NoParams, exactly
2 requests, all 5 rates decorated with deltas), added `rateDate` and
`DataOrigin` to the entity, and introduced an `EgpTrend` enum so the widget
switches on a domain concept instead of doing sign arithmetic.

**Decision:** Accepted

I liked where it placed the two enums: `DataOrigin` in `core/` because
cache-vs-network is infrastructure, `EgpTrend` in the currency domain because
it only exists as a consequence of the inversion. That distinction wasn't in
my prompt.

Three rounds to get here. The first proposal looked correct in shape —
proper layering, sensible naming — but the problems were all in the parts
the spec constrains and a generic clean-architecture template doesn't:
request count, timestamps, and an inverted color convention. Structure
that reads well isn't the same as structure that fits the requirements.



---

## 2026-08-28 — Core layer

**Prompt**

> Implement the core layer only. No feature code yet. [six files listed]
> IMPORTANT: the date is a SUBDOMAIN, not a path segment.
> [verified API response shape pasted in]

**Returned**

Sealed `AppException` / `Failure` hierarchies, `NetworkInfo` with both a
one-shot check and a stream, `AppConstants` with a date-to-URL builder,
`UseCase` base, `DataOrigin` enum. Added equatable, dartz, connectivity_plus.

**Decision:** Accepted

**Why**

I gave it the verified API response and the subdomain constraint up front
rather than letting it infer the URL shape — the date-as-subdomain pattern
is unusual enough that it would likely have produced a path segment.

It used `sealed` classes for both hierarchies, which I hadn't asked for but
kept: it makes the compiler enforce exhaustive handling of every failure
case in the presentation layer. It also handled `connectivity_plus` v6
correctly — that version returns `List<ConnectivityResult>` rather than a
single value, and a naive `!= ConnectivityResult.none` check would not have
compiled.



---

## Domain layer

**Prompt**

> Implement the domain layer only. [entities, repository contract, two use cases]
> Edge cases I want handled explicitly:
> - Yesterday's request fails but today's succeeds — do not fail the whole
    >   screen. Decide and justify what happens to the delta fields.
> - A currency present today but missing yesterday.

**Returned**

Entities with delta fields defaulting to zero, repository contract, and
`GetAllRatesWithChange` doing two calls with per-currency degradation:
today's failure propagates, yesterday's does not.

**Decision:** Edited 

**Why**

I put the edge cases in the prompt because the obvious implementation is
`Left(Failure)` on any failed call — which would hide five valid rates
because a supplementary comparison didn't resolve. It got that right, and
degraded per-currency rather than all-or-nothing.

What I sent back: it used `EgpTrend.unchanged` when yesterday's data was
missing. That's a factual claim we can't make — we don't know the rate was
unchanged, we know nothing. Both render grey, so the user can't distinguish
"flat" from "no data". Added `EgpTrend.unknown`, and the widget hides the
badge for it instead of showing a zero.

The fix it produced was better than what I'd have written: it made the
yesterday map nullable, so a total request failure and a single missing
currency collapse into the same null check rather than two branches.


---

##  Data layer

**Prompt**

> Implement the data layer. [model, remote/local datasources, repository impl]
> No inversion in the datasource — it represents the API faithfully.
> Question before you write it: for getRateHistory, if 2 of the 7 days fail,
> what should happen? Tell me your answer first, then implement.

**Returned**

Model filtering to the 5 targets at parse time, injected `http.Client`,
date-keyed `shared_preferences` cache, and a repository doing inversion at
mapping time with cache fallback. For the history question it chose partial
success — render whatever days resolved, fail only if all 7 fail.

**Decision:** Accepted ✅

**Why**

Asking it to answer the partial-failure question *before* implementing was
deliberate — I wanted the reasoning separately from the code so I could
disagree with the decision rather than reverse-engineer it from a diff. Its
answer matched mine: a 5-point chart is still useful, and one bad date
shouldn't blank the screen.

Two things I challenged and it defended correctly:

- It used `Future.wait` for the 7 history calls, and `Future.wait` discards
  remaining futures on first throw — which would contradict partial success.
  It showed that `getRatesForDate` catches all four exception types and
  returns `Either`, so the futures always complete normally and nothing is
  discarded. My concern was wrong; I'd have written the same check again.
- On a 500 while online it serves cached rates rather than failing, and when
  both remote and cache fail it surfaces the *remote* failure, not the cache
  miss. "Server returned 500" is more actionable to a user than "no cached
  data".

Also worth noting: it injected `http.Client` rather than constructing it
internally, which I hadn't asked for. That's what makes the datasource
testable without a live network.


---

##  BLoCs

**Prompt**

> Implement the presentation BLoCs only. No UI widgets yet.
> [RatesListBloc with connectivity stream, CurrencyDetailBloc taking the
> already-loaded ExchangeRate as a constructor arg]
> Before you write the states, answer this: the user pulls to refresh while
> 5 rates are already on screen, and the refresh fails. What state do you
> emit, and what does the user see?

**Returned**

A single state class with a `status` enum rather than a sealed
Initial/Loading/Loaded/Error hierarchy, plus derived getters
(`isInitialLoading`, `isRefreshing`, `hasRates`). Failure emits preserve the
existing rates list.

**Decision:** Accepted 

**Why**

I asked the refresh-failure question because the default BLoC template —
four sealed states — silently throws away loaded data on any failure. Five
valid rates would vanish behind a full-screen error because a pull-to-refresh
timed out. In an app with an explicit offline mode that's the wrong
behaviour, and it's the kind of thing that only surfaces when you use the
app rather than when you read the code.

It identified the same problem and named the underlying reason: `loading`
means two different things depending on whether data is already present.
Full-screen spinner and inline refresh indicator are the same status with
different context, which a sealed hierarchy can't express without
duplicating the payload into every variant.

One detail I'd have been likely to miss: `_previousConnectivity` starts null,
so the connectivity stream's first emission is never treated as a
restoration. Without that, entering the app offline-then-online would fire a
spurious refresh on launch.