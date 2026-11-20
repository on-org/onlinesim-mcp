# MCP tools

> The 15 tools of onlinesim mcp — inputs, answers, errors and the agent flows for Quick SMS and rentals.

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

<table>
<thead>
  <tr>
    <th>
      Tool
    </th>
    
    <th>
      Kind
    </th>
    
    <th>
      Spends
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <a href="#search_sms_services">
        <code>
          search_sms_services
        </code>
      </a>
    </td>
    
    <td>
      catalog
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#get_sms_service_countries">
        <code>
          get_sms_service_countries
        </code>
      </a>
    </td>
    
    <td>
      catalog
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#find_cheapest_sms_countries">
        <code>
          find_cheapest_sms_countries
        </code>
      </a>
    </td>
    
    <td>
      catalog
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#list_sms_countries">
        <code>
          list_sms_countries
        </code>
      </a>
    </td>
    
    <td>
      catalog
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#list_sms_rentals">
        <code>
          list_sms_rentals
        </code>
      </a>
    </td>
    
    <td>
      catalog
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#get_account_balance">
        <code>
          get_account_balance
        </code>
      </a>
    </td>
    
    <td>
      account
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#order_sms_verification">
        <code>
          order_sms_verification
        </code>
      </a>
    </td>
    
    <td>
      Quick SMS
    </td>
    
    <td>
      reserves the price
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#wait_sms_verification">
        <code>
          wait_sms_verification
        </code>
      </a>
    </td>
    
    <td>
      Quick SMS
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#check_sms_verification">
        <code>
          check_sms_verification
        </code>
      </a>
    </td>
    
    <td>
      Quick SMS
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#cancel_sms_verification">
        <code>
          cancel_sms_verification
        </code>
      </a>
    </td>
    
    <td>
      Quick SMS
    </td>
    
    <td>
      refunds an order without SMS
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#list_sms_orders">
        <code>
          list_sms_orders
        </code>
      </a>
    </td>
    
    <td>
      both
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#rent_sms_number">
        <code>
          rent_sms_number
        </code>
      </a>
    </td>
    
    <td>
      Rent
    </td>
    
    <td>
      reserves, first SMS charges
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#get_sms_rental_messages">
        <code>
          get_sms_rental_messages
        </code>
      </a>
    </td>
    
    <td>
      Rent
    </td>
    
    <td>
      —
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#extend_sms_rental">
        <code>
          extend_sms_rental
        </code>
      </a>
    </td>
    
    <td>
      Rent
    </td>
    
    <td>
      charges at once
    </td>
  </tr>
  
  <tr>
    <td>
      <a href="#cancel_sms_rental">
        <code>
          cancel_sms_rental
        </code>
      </a>
    </td>
    
    <td>
      Rent
    </td>
    
    <td>
      releases a reservation
    </td>
  </tr>
</tbody>
</table>

Catalog answers come from the OnlineSim tariff lists, cached in the server for up to 5 minutes. Balance, orders and
rentals always go to the API. Stock is a hint, not a guarantee: an order can still get `NO_NUMBER`.

## Catalog

### search_sms_services

Find Quick SMS services by name. Read-only.

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        query
      </code>
    </td>
    
    <td>
      string
    </td>
    
    <td>
      no
    </td>
    
    <td>
      Name to search (<code>
        "Telegram"
      </code>
      
      , <code>
        "Google"
      </code>
      
      ). Omit for the top services by availability.
    </td>
  </tr>
</tbody>
</table>

Answer: up to 30 services (50 with a query), each `name [serviceId] | from $price | N countries`. Only services in
stock. If nothing matches, search `"other"` for the catch-all service.

```text
SMS verification services matching "tele" (1):
  telegram [telegram] | from $1.20 | 1 countries
```

### get_sms_service_countries

In-stock countries of one service, most stock first. Read-only.

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        serviceId
      </code>
    </td>
    
    <td>
      string
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      <code>
        serviceId
      </code>
      
       from <code>
        search_sms_services
      </code>
      
      , or the exact service name.
    </td>
  </tr>
</tbody>
</table>

Answer: `country [countryId] | $price | N in stock`. When the id is not exact, a list of similar services
(`Did you mean: …`) instead. Error `ERROR_NO_SERVICE` when nothing matches.

```text
Countries for google [google] (2), most stock first:
  United Kingdom [44] | $0.20 | 100 in stock
  Russia [7] | $0.30 | 100 in stock
```

### find_cheapest_sms_countries

The cheapest in-stock countries of a service — use it instead of guessing a `countryId`. Read-only.

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        serviceId
      </code>
    </td>
    
    <td>
      string
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      <code>
        serviceId
      </code>
      
       from <code>
        search_sms_services
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        limit
      </code>
    </td>
    
    <td>
      integer
    </td>
    
    <td>
      no
    </td>
    
    <td>
      1–20, default 5.
    </td>
  </tr>
</tbody>
</table>

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

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        serviceId
      </code>
    </td>
    
    <td>
      string
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      Exact <code>
        serviceId
      </code>
      
       from the catalog.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        countryId
      </code>
    </td>
    
    <td>
      integer
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      <code>
        countryId
      </code>
      
       from <code>
        get_sms_service_countries
      </code>
      
       / <code>
        find_cheapest_sms_countries
      </code>
      
      .
    </td>
  </tr>
</tbody>
</table>

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

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        orderId
      </code>
    </td>
    
    <td>
      integer
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      Order ID from <code>
        order_sms_verification
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        timeoutSecs
      </code>
    </td>
    
    <td>
      integer
    </td>
    
    <td>
      no
    </td>
    
    <td>
      5–60, default 45. The order is polled every ~5 s.
    </td>
  </tr>
</tbody>
</table>

Answer, one of:

- **received** — the messages, the code found in them (`Code: 123456`) and the number of polls;
- **timeout** — the order is still open; wait again or check later;
- **ended** — the order finished or failed without an SMS (`TZ_OVER_OK`, `ERROR_NO_ITEMS`);
- **not found** — not an active order of this account.

Rate limits (`TRY_AGAIN_LATER`, HTTP 429), `ERROR_UNDEFINED`, `INTERVAL_CONCURRENT_REQUESTS_ERROR` and network errors are
retried until the timeout. At most 4 waits run at the same time.

### check_sms_verification

The inbox of one or more orders, one API call. Read-only.

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        orderIds
      </code>
    </td>
    
    <td>
      integer<span>
        
      </span>
    </td>
    
    <td>
      no
    </td>
    
    <td>
      1–20 Order IDs; omit or <code>
        []
      </code>
      
       for all active orders.
    </td>
  </tr>
</tbody>
</table>

Answer: for one id — waiting / SMS received with the code and every message / not found. For several — one line per
order and a summary (`Received: 1. Waiting: 2. Not found: 0.`). Statuses: `TZ_NUM_WAIT` — waiting for SMS,
`TZ_NUM_ANSWER` — SMS received.

### cancel_sms_verification

Close orders. A closed order without SMS is refunded; an order with an SMS is finished.

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        orderIds
      </code>
    </td>
    
    <td>
      integer<span>
        
      </span>
    </td>
    
    <td>
      no
    </td>
    
    <td>
      1–20 Order IDs; omit or <code>
        []
      </code>
      
       closes <strong>
        all
      </strong>
      
       active orders.
    </td>
  </tr>
</tbody>
</table>

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

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        rentalId
      </code>
    </td>
    
    <td>
      integer
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      <code>
        rentalId
      </code>
      
       from <code>
        list_sms_rentals
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        days
      </code>
    </td>
    
    <td>
      integer
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      One of the day tiers listed for that rental.
    </td>
  </tr>
</tbody>
</table>

Answer: `Receipt ID: [tzid]`, the number (without the country code), the price and whether it is reserved or charged,
the time left for the first SMS, and how to extend and cancel.

Errors: `NO_NUMBER` (no rental number for that country/period — pick another from `list_sms_rentals`),
`UNDEFINED_DAYS`, `UNDEFINED_COUNTRY`, `WARNING_LOW_BALANCE`, `INTERVAL_CONCURRENT_REQUESTS_ERROR`.

### get_sms_rental_messages

Rental inboxes, one API call. Read-only.

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        receiptIds
      </code>
    </td>
    
    <td>
      integer<span>
        
      </span>
    </td>
    
    <td>
      no
    </td>
    
    <td>
      1–20 Receipt IDs; omit or <code>
        []
      </code>
      
       for all active rentals.
    </td>
  </tr>
</tbody>
</table>

Answer: per rental — the number, status (waiting for first SMS / active / frozen), time left, the extension periods
with prices, and the messages newest first as `sender: text`, with the code of the newest SMS.

### extend_sms_rental

Add days to a rental. **Spends balance** at once.

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        receiptId
      </code>
    </td>
    
    <td>
      integer
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      Receipt ID.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        days
      </code>
    </td>
    
    <td>
      integer
    </td>
    
    <td>
      yes
    </td>
    
    <td>
      One of <strong>
        this rental's
      </strong>
      
       extension periods, as listed by <code>
        get_sms_rental_messages
      </code>
      
       (not a <code>
        list_sms_rentals
      </code>
      
       tier).
    </td>
  </tr>
</tbody>
</table>

Only a confirmed rental (after its first SMS) that was rented with extension can be extended. The tool reads the rental
first and explains a refusal: not confirmed yet, cannot be extended, or `days` is not one of its periods (with the
list). Answer: the new total days, time left and total cost.

Errors: `WARNING_LOW_BALANCE`, `TRY_AGAIN_LATER` (the API refused, e.g. a repeat within 10 s or the rental closed).

### cancel_sms_rental

Close rentals.

<table>
<thead>
  <tr>
    <th>
      Argument
    </th>
    
    <th>
      Type
    </th>
    
    <th>
      Required
    </th>
    
    <th>
      Description
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        receiptIds
      </code>
    </td>
    
    <td>
      integer<span>
        
      </span>
    </td>
    
    <td>
      no
    </td>
    
    <td>
      1–20 Receipt IDs; omit or <code>
        []
      </code>
      
       closes <strong>
        all
      </strong>
      
       active rentals.
    </td>
  </tr>
</tbody>
</table>

A rental still waiting for its first SMS can be closed 120 s after it started; its reservation is released. A confirmed
rental closes without refund. Refusals come back per rental: `NO_COMPLETE_TZID` with `guard_secs`, `NO_CLOSE_RENT_US`
(US numbers close only when the period ends), `ERROR_NO_OPERATIONS` (unknown id), `TRY_AGAIN_LATER`.

## Errors any tool can return

<table>
<thead>
  <tr>
    <th>
      Code
    </th>
    
    <th>
      Meaning
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        ERROR_WRONG_KEY
      </code>
    </td>
    
    <td>
      No or wrong API key — run <code>
        onlinesim login
      </code>
      
       or set <code>
        ONLINESIM_APIKEY
      </code>
      
      .
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        ACCOUNT_BLOCKED
      </code>
    </td>
    
    <td>
      The account is blocked; contact OnlineSim support.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        ACCOUNT_CLEANED
      </code>
    </td>
    
    <td>
      The account was deleted.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        USER_NOT_ACTIVATED
      </code>
    </td>
    
    <td>
      The account email is not confirmed.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        API_ACCESS_DISABLED
      </code>
    </td>
    
    <td>
      API access is off in the profile.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        API_ACCESS_IP
      </code>
    </td>
    
    <td>
      This IP is not in the profile allowlist.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        TRY_AGAIN_LATER
      </code>
    </td>
    
    <td>
      Rate limit (400 requests/min per profile) or a temporary error — wait and retry once.
    </td>
  </tr>
</tbody>
</table>

An unknown code is shown as is with a generic hint.
