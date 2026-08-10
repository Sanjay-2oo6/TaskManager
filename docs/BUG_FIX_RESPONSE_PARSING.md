# Bug Fix: Response Parsing Error in Organizations List Screen

**Date:** July 29, 2026  
**Status:** ✅ **FIXED**

---

## Issue

**Error:** `NoSuchMethodError` - Red error screen when viewing Organizations List

**Cause:** Incorrect parsing of Dio Response object

---

## Root Cause

```dart
// ❌ WRONG
final response = snapshot.data;
final organizations = response?['data'] as List? ?? [];
```

`snapshot.data` is a Dio `Response` object, not a Map. Must access `.data` property first:

```
Response {
  statusCode: 200,
  data: {  // ← The actual JSON response
    success: true,
    data: [organizations...],
    pagination: {...}
  }
}
```

---

## Solution

```dart
// ✅ CORRECT
final response = snapshot.data as dynamic;
final organizations = (response?.data?['data'] as List?) ?? [];
```

---

## File Modified

`frontend/lib/presentation/screens/organizations_list_screen.dart` (line 108)

---

## Result

✅ Organizations now load correctly  
✅ Shows list or "No organizations yet" message  
✅ Error state only on actual API failure

