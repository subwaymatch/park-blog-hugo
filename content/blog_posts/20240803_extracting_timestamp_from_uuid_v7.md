---
title: "Extract Timestamp from UUID v7 using Javascript"
date: 2024-08-03
draft: false
categories:
  - Javascript
tags:
  - uuid
---

## Time-based UUIDs

A UUID (Universally Unique Identifier) is a 128-bit number used to uniquely identify records or information.

Time-based UUIDs are a category of UUIDs that incorporate the current timestamp into their structure, allowing for chronological ordering of the generated UUIDs. They are particularly useful in distributed systems where unique identifiers that are sortable by creation time are beneficial. There are several versions of time-based UUIDs, including UUID v1, UUID v6, and UUID v7, each with different methods of encoding the timestamp and other components.

#### UUID v7

UUID v7 is a more recent proposal that focuses on using Unix epoch timestamps and random bits, providing a more privacy-preserving and scalable identifier. It eliminates the use of the MAC address and clock sequence, replacing them with random values.

While a higher UUID version does not necessarily mean that the preceding version is deprecated, the [IETF Draft on UUID Revision](https://datatracker.ietf.org/doc/html/draft-ietf-uuidrev-rfc4122bis-00#section-5.7) suggests that "Implementations SHOULD utilize UUID version 7 over UUID version 1 and 6 if possible".

### Structure of UUID v7

Here is a breakdown of the bits that make up a UUID v7 value.

```plaintext
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           unix_ts_ms                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          unix_ts_ms           |  ver  |       rand_a          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|var|                        rand_b                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            rand_b                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

👆 Source: [A Universally Unique IDentifier (UUID) URN Namespace
](https://datatracker.ietf.org/doc/html/draft-ietf-uuidrev-rfc4122bis-00)

Here is what a UUID v7 looks like.

```plaintext
aaaaaaaa-bbbb-7ccc-yddd-eeeeeeeeeeee
```

- The first 8 hex characters (aaaaaaaa) represent the high bits of the timestamp.
- The next 4 hex characters (bbbb) continue the timestamp.
- The 7 indicates the version (UUID v7).
- The next 3 hex characters (ccc) continue the timestamp.
- The y indicates the variant.
- The remaining 3 hex characters (ddd)
- The last 12 hex characters (eeeeeeeeeeee) are random bits.

### Extract Timestamp

The timestamp in a UUID v7 is represented as the number of milliseconds since the Unix epoch (January 1, 1970). From the previous section, we already know that the first 12 bits represent the timestamp. To extract the timestamp from a UUID v7 value, grab the first 48 bits (12 characters excluding the dash) and parse them as an integer. Here is working example using Typescript.

```typescript
// extract Unix timestamp from a UUID v7 value without an external library
function extractTimestampFromUUIDv7(uuid: string): Date {
  // split the UUID into its components
  const parts = uuid.split("-");

  // the second part of the UUID contains the high bits of the timestamp (48 bits in total)
  const highBitsHex = parts[0] + parts[1].slice(0, 4);

  // convert the high bits from hex to decimal
  // the UUID v7 timestamp is the number of milliseconds since Unix epoch (January 1, 1970)
  const timestampInMilliseconds = parseInt(highBitsHex, 16);

  // convert the timestamp to a Date object
  const date = new Date(timestampInMilliseconds);

  return date;
}

// sample usage:
const uuid = "01911825-7f8f-74c9-85bc-55b034e2af75";
const timestamp = extractTimestampFromUUIDv7(uuid);

// check output
console.log(timestamp);
// prints "Sat Aug 03 2024 07:09:56 GMT-0500 (Central Daylight Time)"
```
