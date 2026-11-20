---
title: MCP tools
description: The 15 tools of onlinesim mcp — inputs, answers, errors and the agent flows for Quick SMS and rentals.
navigation:
  order: 3
---

Every tool answers with plain text written for the agent: the data, the ids in `[brackets]` and what to do next.
A failed call is an MCP tool error (`isError: true`) whose text explains the API error code and the next step; it is
not a protocol error. Arguments are camelCase JSON.

Ids in `[brackets]`: `serviceId` (slug, e.g. `telegram`), `countryId` / `rentalId` (numeric country code, e.g. `7`),
Order ID / Receipt ID (`tzid` of an order or a rental). Never invent them — take them from catalog tools or
`list_sms_orders`.

Bulk tools take `orderIds` / `receiptIds`: 1–20 ids (duplicates are dropped), or omit / `[]` for every active one.
Cancel-all only when the user explicitly asks to close everything. One bulk call, never one call per number.

## Agent flows

Quick SMS:

```text
get_account_balance
→ search_sms_services → find_cheapest_sms_countries   (or get_sms_service_countries)
→ order_sms_verification(serviceId, countryId)
→ the user enters the number on the target site and requests the SMS
→ wait_sms_verification(orderId)                       (or check_sms_verification every 15–30 s)
→ cancel_sms_verification(orderIds)
```

Rent:

```text
list_sms_rentals → rent_sms_number(rentalId, days)
→ get_sms_rental_messages(receiptIds)                  (every 15–30 s)
→ extend_sms_rental(receiptId, days) / cancel_sms_rental(receiptIds)
```

| Tool | Kind | Spends |
|---|---|---|
| [`search_sms_services`](#search_sms_services) | catalog | — |
| [`get_sms_service_countries`](#get_sms_service_countries) | catalog | — |
| [`find_cheapest_sms_countries`](#find_cheapest_sms_countries) | catalog | — |
| [`list_sms_countries`](#list_sms_countries) | catalog | — |
| [`list_sms_rentals`](#list_sms_rentals) | catalog | — |
| [`get_account_balance`](#get_account_balance) | account | — |
| [`order_sms_verification`](#order_sms_verification) | Quick SMS | reserves the price |
| [`wait_sms_verification`](#wait_sms_verification) | Quick SMS | — |
| [`check_sms_verification`](#check_sms_verification) | Quick SMS | — |
| [`cancel_sms_verification`](#cancel_sms_verification) | Quick SMS | refunds an order without SMS |
| [`list_sms_orders`](#list_sms_orders) | both | — |
| [`rent_sms_number`](#rent_sms_number) | Rent | reserves, first SMS charges |
| [`get_sms_rental_messages`](#get_sms_rental_messages) | Rent | — |
| [`extend_sms_rental`](#extend_sms_rental) | Rent | charges at once |
| [`cancel_sms_rental`](#cancel_sms_rental) | Rent | releases a reservation |

Catalog answers come from the OnlineSim tariff lists, cached in the server for up to 5 minutes. Balance, orders and
rentals always go to the API. Stock is a hint, not a guarantee: an order can still get `NO_NUMBER`.

## Catalog

### search_sms_services

Find Quick SMS services by name. Read-only.

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | no | Name to search (`"Telegram"`, `"Google"`). Omit for the top services by availability. |

Answer: up to 30 services (50 with a query), each `name [serviceId] | from $price | N countries`. Only services in
stock. If nothing matches, search `"other"` for the catch-all service.

```text
SMS verification services matching "tele" (1):
  telegram [telegram] | from $1.20 | 1 countries
```

### get_sms_service_countries

In-stock countries of one service, most stock first. Read-only.

| Argument | Type | Required | Description |
|---|---|---|---|
| `serviceId` | string | yes | `serviceId` from `search_sms_services`, or the exact service name. |

Answer: `country [countryId] | $price | N in stock`. When the id is not exact, a list of similar services
(`Did you mean: …`) instead. Error `ERROR_NO_SERVICE` when nothing matches.

```text
Countries for google [google] (2), most stock first:
  United Kingdom [44] | $0.20 | 100 in stock
  Russia [7] | $0.30 | 100 in stock
```

### find_cheapest_sms_countries

The cheapest in-stock countries of a service — use it instead of guessing a `countryId`. Read-only.

| Argument | Type | Required | Description |
|---|---|---|---|
| `serviceId` | string | yes | `serviceId` from `search_sms_services`. |
| `limit` | integer | no | 1–20, default 5. |

Answer: like `get_sms_service_countries`, sorted by price. Suggestions or `ERROR_NO_SERVICE` the same way.

### list_sms_countries

Every Quick SMS country (directory, no prices). No arguments. Read-only.

Answer: `name · countryId [code] · on|off`. The `countryId` is the country's dial code. For prices and stock use a
`serviceId` with the two tools above.

### list_sms_rentals

The long-term rental catalog. No arguments. Read-only.

Answer: per country `name [rentalId] | in stock | OUT OF STOCK`, and per rent period `N day(s) | $price | in stock`.
Countries marked `charged at once, no refund` (e.g. US) are charged when rented instead of on the first SMS.

```text
Long-term SMS rental numbers (keep the same receive-only number for days):
  russia [7] | in stock
    1 day(s) | $1.00 | in stock
    3 day(s) | $2.50 | in stock
    7 day(s) | $5.00 | in stock
```

## Account

### get_account_balance

No arguments. Read-only.

Answer: available for orders (= balance − frozen), total balance, frozen `zbalance` (reserved by open orders and
unconfirmed rentals), income when the account has it, and the top-up link.

```text
Available for orders: $7.50
Account balance: $10.00
Frozen (zbalance, reserved by open orders/rentals): $2.50
```

## Quick SMS

### order_sms_verification

Buy a number for one service. **Spends balance**: the price is reserved at once and refunded if the order is closed
without an SMS.

| Argument | Type | Required | Description |
|---|---|---|---|
| `serviceId` | string | yes | Exact `serviceId` from the catalog. |
| `countryId` | integer | yes | `countryId` from `get_sms_service_countries` / `find_cheapest_sms_countries`. |

Answer: `Order ID: [tzid]`, the phone number, service, country, and the cancel guard.

```text
Quick SMS number ordered (price reserved on the balance).
Order ID: [1]
Phone number (use this on the target service): +7900000001
Service: telegram | Country: 7
```

Errors: `NO_NUMBER` (try another country), `WARNING_LOW_BALANCE`, `ERROR_NO_SERVICE`, `UNDEFINED_COUNTRY`,
`EXCEEDED_CONCURRENT_OPERATIONS` (too many open numbers without SMS), `INTERVAL_CONCURRENT_REQUESTS_ERROR`,
subscription accounts: `COUNTRY_NOT_ALLOWED`, `SUBSCRIPTION_ERR_SERVICE`, `SUBSCRIPTION_WRONG_ACTIVE_PACKAGE_ID`,
`NO_ACTIVE_PACKAGE`.

### wait_sms_verification

Wait for one order until it has an SMS, ends, or the timeout passes. Read-only: it never closes the order and never
moves it to the next SMS, so a later check or wait shows the same messages. The user must already have requested the
SMS on the target site.

| Argument | Type | Required | Description |
|---|---|---|---|
| `orderId` | integer | yes | Order ID from `order_sms_verification`. |
| `timeoutSecs` | integer | no | 5–60, default 45. The order is polled every ~5 s. |

Answer, one of:

- **received** — the messages, the code found in them (`Code: 123456`) and the number of polls;
- **timeout** — the order is still open; wait again or check later;
- **ended** — the order finished or failed without an SMS (`TZ_OVER_OK`, `ERROR_NO_ITEMS`);
- **not found** — not an active order of this account.

Rate limits (`TRY_AGAIN_LATER`, HTTP 429), `ERROR_UNDEFINED`, `INTERVAL_CONCURRENT_REQUESTS_ERROR` and network errors are
retried until the timeout. At most 4 waits run at the same time.

### check_sms_verification

The inbox of one or more orders, one API call. Read-only.

| Argument | Type | Required | Description |
|---|---|---|---|
| `orderIds` | integer[] | no | 1–20 Order IDs; omit or `[]` for all active orders. |

Answer: for one id — waiting / SMS received with the code and every message / not found. For several — one line per
order and a summary (`Received: 1. Waiting: 2. Not found: 0.`). Statuses: `TZ_NUM_WAIT` — waiting for SMS,
`TZ_NUM_ANSWER` — SMS received.

### cancel_sms_verification

Close orders. A closed order without SMS is refunded; an order with an SMS is finished.

| Argument | Type | Required | Description |
|---|---|---|---|
| `orderIds` | integer[] | no | 1–20 Order IDs; omit or `[]` closes **all** active orders. |

Answer: one block per order — closed, or not closed with the code and its explanation. An order without SMS cannot be
closed during its guard interval (120 s from the order, 300 s for WhatsApp): that comes back as a refusal with
`NO_COMPLETE_TZID`, the phone, service, country and `guard_secs` — wait that long and retry. Other codes:
`ERROR_WRONG_TZID` (unknown id), `INTERVAL_CONCURRENT_REQUESTS_ERROR` (the same order touched less than 5 s ago).

### list_sms_orders

Active Quick SMS orders and rentals with their ids — to recover after a crash or a lost context. No arguments.
Read-only.

Answer: `Order ID [tzid] | number | service | country | status` and
`Receipt ID [tzid] | number | country | days | rental status | time left`.

## Rent

A rental keeps a number for days and receives every SMS sent to it. `rent_sms_number` reserves the price: the rental
waits up to ~20 minutes for its first SMS (status *waiting for first SMS*). The first real SMS confirms it and charges
the price; without one the rental closes and the reservation is released. Countries marked `charged at once` in
`list_sms_rentals` are confirmed and charged immediately.

### rent_sms_number

Rent a number. **Spends balance** (reservation, charged by the first SMS).

| Argument | Type | Required | Description |
|---|---|---|---|
| `rentalId` | integer | yes | `rentalId` from `list_sms_rentals`. |
| `days` | integer | yes | One of the day tiers listed for that rental. |

Answer: `Receipt ID: [tzid]`, the number (without the country code), the price and whether it is reserved or charged,
the time left for the first SMS, and how to extend and cancel.

Errors: `NO_NUMBER` (no rental number for that country/period — pick another from `list_sms_rentals`),
`UNDEFINED_DAYS`, `UNDEFINED_COUNTRY`, `WARNING_LOW_BALANCE`, `INTERVAL_CONCURRENT_REQUESTS_ERROR`.

### get_sms_rental_messages

Rental inboxes, one API call. Read-only.

| Argument | Type | Required | Description |
|---|---|---|---|
| `receiptIds` | integer[] | no | 1–20 Receipt IDs; omit or `[]` for all active rentals. |

Answer: per rental — the number, status (waiting for first SMS / active / frozen), time left, the extension periods
with prices, and the messages newest first as `sender: text`, with the code of the newest SMS.

### extend_sms_rental

Add days to a rental. **Spends balance** at once.

| Argument | Type | Required | Description |
|---|---|---|---|
| `receiptId` | integer | yes | Receipt ID. |
| `days` | integer | yes | One of **this rental's** extension periods, as listed by `get_sms_rental_messages` (not a `list_sms_rentals` tier). |

Only a confirmed rental (after its first SMS) that was rented with extension can be extended. The tool reads the rental
first and explains a refusal: not confirmed yet, cannot be extended, or `days` is not one of its periods (with the
list). Answer: the new total days, time left and total cost.

Errors: `WARNING_LOW_BALANCE`, `TRY_AGAIN_LATER` (the API refused, e.g. a repeat within 10 s or the rental closed).

### cancel_sms_rental

Close rentals.

| Argument | Type | Required | Description |
|---|---|---|---|
| `receiptIds` | integer[] | no | 1–20 Receipt IDs; omit or `[]` closes **all** active rentals. |

A rental still waiting for its first SMS can be closed 120 s after it started; its reservation is released. A confirmed
rental closes without refund. Refusals come back per rental: `NO_COMPLETE_TZID` with `guard_secs`, `NO_CLOSE_RENT_US`
(US numbers close only when the period ends), `ERROR_NO_OPERATIONS` (unknown id), `TRY_AGAIN_LATER`.

## Errors any tool can return

| Code | Meaning |
|---|---|
| `ERROR_WRONG_KEY` | No or wrong API key — run `onlinesim login` or set `ONLINESIM_APIKEY`. |
| `ACCOUNT_BLOCKED` | The account is blocked; contact OnlineSim support. |
| `ACCOUNT_CLEANED` | The account was deleted. |
| `USER_NOT_ACTIVATED` | The account email is not confirmed. |
| `API_ACCESS_DISABLED` | API access is off in the profile. |
| `API_ACCESS_IP` | This IP is not in the profile allowlist. |
| `TRY_AGAIN_LATER` | Rate limit (400 requests/min per profile) or a temporary error — wait and retry once. |

An unknown code is shown as is with a generic hint.
