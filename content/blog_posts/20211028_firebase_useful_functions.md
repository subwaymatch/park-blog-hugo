---
title: "Two useful Firebase hacks"
date: 2021-10-28
categories:
  - Firebase
tags:
  - firebase
  - cloud functions
---

I was once an avid user of [Firebase](https://firebase.google.com/). But over time, I gradually became fond of PostgreSQL-backed open-source alternatives like [Hasura](https://hasura.io/) or [Supabase](https://supabase.io/) and moved on. The two things that I don't miss in Firebase are:

1. No way to change custom user claims in the dashboard
2. No easy one-click solution to auto-timestamp document updates in Firestore 😤

Here are two Firebase (serverless) functions to make your life easier. **Both are slight modifications of community knowledge from StackOverflow.**

## Mirror custom claims from a collection

You can implement granular access control in Firebase using custom claims. But guess what - there's no way to do that on the dashboard UI. 😡 You're forced to build your own backend with some code that looks like below (code from [Firebase Admin docs](https://firebase.google.com/docs/auth/admin/custom-claims)):

```javascript
// Set admin privilege on the user corresponding to uid.
getAuth()
  .setCustomUserClaims(uid, { admin: true })
  .then(() => {
    // The new custom claims will propagate to the user's ID token the
    // next time a new one is issued.
  });
```

A smart workaround is to create a Firestore collection and mirror any custom claims on that table using a Firebase function.

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const auth = admin.auth();

interface ClaimsDocumentData extends admin.firestore.DocumentData {
  _lastCommitted?: admin.firestore.Timestamp;
}

// since Firebase auth doesn't provide a UI to set custom claims,
// use userClaims collection as a mirror
export const mirrorCustomClaims = functions.firestore
  .document("userClaims/{uid}")
  .onWrite(async (change, context) => {
    const beforeData: ClaimsDocumentData = change.before.data() || {};
    const afterData: ClaimsDocumentData = change.after.data() || {};

    // skip updates where _lastCommitted field changed
    // to avoid infinite loops
    const skipUpdate =
      beforeData._lastCommitted &&
      afterData._lastCommitted &&
      !beforeData._lastCommitted.isEqual(afterData._lastCommitted);

    if (skipUpdate) {
      return;
    }

    // create a new JSON payload and check that it's under
    // the 1000 character limit
    const { _lastCommitted, ...newClaims } = afterData;
    const stringifiedClaims = JSON.stringify(newClaims);

    if (stringifiedClaims.length > 1000) {
      console.error(
        "New custom claims object string exceeds 1000 characters",
        stringifiedClaims
      );
      return;
    }

    const uid = context.params.uid;
    await auth.setCustomUserClaims(uid, newClaims);

    await change.after.ref.update({
      _lastCommitted: admin.firestore.FieldValue.serverTimestamp(),
      ...newClaims,
    });
  });
```

## Auto-timestamp document updates

This is another common use-case. Add any tables you'd like to auto-timestamp to the `collectionsToTimestamp` array.

```typescript
export const autoTimestamp = functions.firestore
  .document("{colId}/{docId}")
  .onWrite(async (change, context) => {
    // the collections to trigger automatic insertion of
    // createdAt/modifedAt timestamps
    const collectionsToTimestamp = ["myCollection1", "myCollection2"];

    // do nothing if the changed collection is
    // not one of the target collections
    if (collectionsToTimestamp.indexOf(context.params.colId) === -1) {
      return null;
    }

    // identify event type (create, update, or delete)
    const isDocCreated = !change.before.exists && change.after.exists;
    const isDocUpdated = change.before.exists && change.after.exists;
    const isDocDeleted = change.before.exists && !change.after.exists;

    // do nothing if the doc is deleted
    if (isDocDeleted) {
      return null;
    }

    // simplify input data
    const after: any = change.after.exists ? change.after.data() : null;
    const before: any = change.before.exists ? change.before.data() : null;

    // prevent update loops from triggers
    const canUpdate = () => {
      // If update trigger
      if (before.updatedAt && after.updatedAt) {
        if (after.updatedAt._seconds !== before.updatedAt._seconds) {
          return false;
        }
      }

      // if create trigger
      if (!before.createdAt && after.createdAt) {
        return false;
      }

      return true;
    };

    // if newly created doc, add createdAt
    if (isDocCreated) {
      return change.after.ref
        .set(
          {
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        )
        .catch((err: any) => {
          console.error(err);
          return false;
        });
    }

    // if updated doc, add updatedAt
    if (isDocUpdated && canUpdate()) {
      return change.after.ref
        .set(
          {
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        )
        .catch((err: any) => {
          console.error(err);
          return false;
        });
    }

    return null;
  });
```
