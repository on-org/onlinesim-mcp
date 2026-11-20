---
title: Changelog
description: Release notes of onlinesim-mcp.
navigation:
  order: 6
---

Binaries and notes of every release are on [GitHub Releases](https://github.com/on-org/onlinesim-mcp/releases).

## 0.1.17

Aligned with the current OnlineSim API.

- `wait_sms_verification` is read-only: it no longer moves the order to its next SMS after a code. It retries rate
  limits and temporary errors until the timeout and reports an order that ended without SMS.
- The API key is sent as a Bearer header; HTTP 456 / 429 answers are reported as API errors.
- Rentals: time left is shown correctly (the API gives minutes); `extend_sms_rental` takes one of the rental's own
  extension periods and explains why a rental cannot be extended; renting is a reservation charged by the first SMS
  (at once for countries marked `charged at once`); stock per rent period; clearer `NO_NUMBER`, `NO_COMPLETE_TZID` and
  `NO_CLOSE_RENT_US` answers.
- Error explanations match the current API codes.
- The balance shows the amount available for orders (balance − frozen), also in the tray.
- `onlinesim login` does not save a key the API rejects.
- Duplicate ids no longer count towards the 20-id limit.

## 0.1.16 and earlier

See [GitHub Releases](https://github.com/on-org/onlinesim-mcp/releases).
