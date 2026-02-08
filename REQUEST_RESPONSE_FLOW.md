# Request → Response → Parsing Flow Documentation

**Framework:** sc_appframework  
**Date:** February 2026  
**Purpose:** Complete flow documentation from API request initiation to parsed model response

---

## Overview

The sc_appframework provides a custom HTTP client wrapper around Dart's `http` package. It handles request building, execution, response parsing, offline caching, and retry logic in a single unified API.

---

## Initialization

### Setup (Required Before Any Request)

**File:** App's `main.dart`  
**Method:** `SCNetworkApi().init()`  
**When:** App startup (in `main()` or before first request)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SCNetworkApi().init(
    baseUrl: 'https://api.example.com',
    enableLog: true,           // Optional: Enable request logging
    enableBodyLog: true,        // Optional: Enable body logging
    enableHeaderLog: true,      // Optional: Enable header logging
  );
  
  runApp(MyApp());
}
```

**What it does:**
- Sets the base URL for all API requests
- Initializes Hive storage for GET cache
- Configures logging preferences

---

## Architecture Pattern

**Pattern:** Singleton

```dart
static final SCNetworkApi _instance = SCNetworkApi._internal();
factory SCNetworkApi() => _instance;
```

**Usage:** Access the same instance throughout the app:
```dart
final api = SCNetworkApi();  // Same instance everywhere
```

---

## REQUEST FLOW

### 1. Header Building

**File:** `lib/src/network/sc_network_api.dart`  
**Method:** `addToHeader(Map<String, String> headerEntry)`  
**Line:** ~180

**Purpose:** Set global headers that apply to all requests

```dart
// Set global headers (e.g., after login)
SCNetworkApi().addToHeader({
  'Authorization': 'Bearer $token',
  'Accept-Language': 'en',
});
```

**Note:** You can also pass headers per-request:
```dart
await SCNetworkApi().request(
  Method.GET,
  '/users',
  headers: {'X-Custom-Header': 'value'},  // Per-request header
);
```

**Behavior:** Per-request headers are merged with global headers

---

### 2. Entry Point (Main Request Method)

**File:** `lib/src/network/sc_network_api.dart`  
**Method:** `request<T>(Method method, String route, {...})`  
**Line:** ~184

**Purpose:** Main entry point for all HTTP requests

```dart
Future<Either<Failure, dynamic>> request<T>(
  Method method,           // GET, POST, PUT, DELETE, PATCH, MULTIPART
  String route,            // API endpoint path
  {
    Map<String, String> headers = const {},
    dynamic body,
    Function(dynamic)? serializer,       // Model.fromJson function
    Map<String, String?> params = const {},
    Map<String, List<String>> repeatableParams = const {},
    Map<String, String?> filter = const {},
    ResponseType responseType = ResponseType.SINGLE,  // SINGLE or LIST
    bool raw = false,
    int? page,
    int perPage = 30,
    String? searchQuery,
    List<String>? searchIn,
    bool retry = false,
    bool cacheRequest = false,
    FilePayload? filePayload,
    void Function(int bytes, int totalBytes)? onProgress,
    int requestId = -1,
    bool enableLog = false,
    bool enableBodyLog = false,
    bool enableHeaderLog = false,
    int? timeoutSeconds,
    bool decodeUtf8 = false,
    bool enableGetCache = false,
  }
)
```

**Example Usage:**
```dart
typedef LoginUserResponse = Either<Failure, AuthResponse>;

Future<LoginUserResponse> loginUser(User user) async {
  return SCNetworkApi().request<AuthResponse>(
    Method.POST,
    "auth/login",
    serializer: (json) => AuthResponse.fromJson(json),
    body: jsonEncode(user),
  );
}
```

---

### 3. URI Building

**File:** `lib/src/network/sc_network_api.dart`  
**Method:** `_buildUri()`  
**Line:** ~619

**Purpose:** Constructs the complete URI with query parameters

**Steps:**
1. Maps all query parameters from `Map<String, dynamic>`
2. Adds pagination parameters (`page`, `perPage`)
3. Adds search parameters (`search`, `search_in`)
4. Applies filters if provided
5. Handles repeatable parameters (arrays/lists)
6. Validates URI format using regex
7. Returns formatted `Uri` object ready for HTTP request

**Example:**
```dart
// Input:
route = "/users"
params = {"status": "active"}
page = 1
perPage = 20
filter = {"role": "admin"}

// Output:
Uri: https://api.example.com/users?status=active&page=1&per_page=20&filter=role,admin
```

**Logged Output (if enableLog = true):**
```
URL: https://api.example.com/users?status=active&page=1&per_page=20
```

---

### 4. Cache Request (Offline Queue)

**File:** `lib/src/network/sc_network_api.dart`  
**Line:** ~232

**Purpose:** Deduplication mechanism for offline request queue

**When Used:** When `cacheRequest: true` is set

**How It Works:**
1. Checks if request with same `requestId` already exists in `_cachedRequests`
2. If NOT found → Adds request to queue
3. If found → Skips adding (prevents duplicates)
4. Serializes queue to SharedPreferences
5. When request succeeds → Removes from queue

**Use Case:**
```dart
// User clicks "Submit Order" while offline
await SCNetworkApi().request(
  Method.POST,
  '/orders',
  body: orderData,
  cacheRequest: true,      // Queue this request
  requestId: 12345,        // Unique ID for deduplication
);

// If user clicks again → Won't create duplicate
// When online → Automatically retries queued requests
```

**Prevents:** Multiple submissions of the same request when connectivity is restored

---

### 5. HTTP Execution (_makeRequest)

**File:** `lib/src/network/sc_network_api.dart`  
**Method:** `_makeRequest()`  
**Line:** ~457

**Purpose:** Executes the actual HTTP request using the `http` package

**Flow:**
1. **Switch on HTTP method:**
   - `Method.GET` → `http.get()`
   - `Method.POST` → `http.post()`
   - `Method.PUT` → `http.put()`
   - `Method.DELETE` → `http.delete()`
   - `Method.PATCH` → `http.patch()`
   - `Method.MULTIPART` → `SCMultipartRequest()` (file upload)

2. **All requests wrapped with timeout:**
   ```dart
   .timeout(Duration(seconds: timeoutSeconds), onTimeout: () {
     throw TimeoutException(SCConstants.TIMEOUT_EXCEPTION_MESSAGE);
   });
   ```

3. **MULTIPART special handling (file uploads):**
   - Creates `SCMultipartRequest` with progress tracking
   - Attaches files from `filePayload.filePaths`
   - Sends as `multipart/form-data`
   - **Optionally deletes uploaded files after success** (if `filePayload.deleteFile = true`)

**Returns:** `http.Response?`

---

### 6. Failed Request Handling

**File:** `lib/src/network/sc_network_api.dart`  
**Line:** ~275 (catch block)

**Purpose:** Handle network failures and provide cache fallback

**Flow:**

#### Exception Caught (Network Error, Timeout, etc.)

**Option A: GET Request with Cache Enabled**
```dart
if (enableGetCache && method == Method.GET) {
  // Try to load from Hive cache
  responseBody = jsonDecode(_getCacheBox?.get(uri.toString()));
  
  if (responseBody != null) {
    // Return cached data
    return Right(cachedData);
  } else {
    // No cache available
    return Left(SCConstants.CacheFailure);
  }
}
```

**Option B: No Cache Available**
```dart
return Left(SCConstants.NetworkFailure);
```

#### Retry Logic (Line ~419)

```dart
if (result!.isLeft() && retry) {
  await Future.delayed(const Duration(seconds: 5), () async {
    result = await request(...);  // Recursive retry
  });
}
```

**Behavior:**
- Waits **5 seconds**
- Recursively calls `request()` with same parameters

---

## RESPONSE & PARSING FLOW

### Complete Response Processing Pipeline

```
HTTP Response
    ↓
Status Validation
    ↓
JSON Decoding
    ↓
Response Wrapper (Single/List)
    ↓
User Serializer
    ↓
Either<Failure, T>
```

---

### 1. HTTP Response Received

**File:** `lib/src/network/sc_network_api.dart`  
**Line:** ~273

```dart
response = await _makeRequest(method, uri, body, filePayload, 
                               onProgress, requestHeaders, requestTimeoutSeconds);
```

**Type:** `http.Response?` from `package:http/http.dart`

---

### 2. Status Validation (Two-Level Check)

**File:** `lib/src/network/sc_network_api.dart`  
**Line:** ~336

**Step 1: Decode response body**
```dart
statusAndMessage = jsonDecode(response.body);
```

**Step 2: Check HTTP status code**
```dart
if (response.statusCode != 200) {
  isFailure = true;
}
```

**Step 3: Check internal status field**
```dart
else if (response.statusCode == 200 &&
         statusAndMessage.containsKey("status") &&
         statusAndMessage["status"] != 1) {
  isFailure = true;
}
```

**Expected Response Structure:**
```json
{
  "status": 1,           // Must be 1 for success
  "message": "Success",
  "data": { ... }        // Actual payload
}
```

---

### 3. JSON Decoding

**File:** `lib/src/network/sc_network_api.dart`  
**Line:** ~372

```dart
responseBody = decodeUtf8
    ? jsonDecode(utf8.decode(response.bodyBytes))  // UTF-8 encoding
    : jsonDecode(response.body);                    // Standard decoding
```

**Result:** `Map<String, dynamic>`

---

### 4. Response Wrapper Selection

**File:** `lib/src/network/sc_network_api.dart`  
**Line:** ~390

**Routes to appropriate wrapper based on `ResponseType`:**

```dart
switch (responseType) {
  case ResponseType.SINGLE:
    result = Right<Failure, T>(
      SingleResponse<T>.fromJson(
        responseBody,
        serializer,
        _jsonDataLevel,
        false
      ).data
    );
    break;
    
  case ResponseType.LIST:
    result = Right<Failure, List<T>>(
      ListResponse<T>.fromJson(
        responseBody,
        serializer,
        _jsonDataLevel,
        false
      ).data
    );
    break;
}
```

---

### 5. Navigate to Data Field

**File:** `lib/src/models/single_response.dart`  
**Line:** ~17

```dart
// Default: _jsonDataLevel = ["data"]
for (var level in jsonDataLevel) {
  json = json[level];
}
```

**Example:**
```json
// Original JSON:
{
  "status": 1,
  "message": "Success",
  "data": {            // ← Navigate here
    "token": "abc123",
    "userId": 456
  }
}

// After navigation:
json = {
  "token": "abc123",
  "userId": 456
}
```

**Customizable:** You can change `jsonDataLevel` globally:
```dart
SCNetworkApi().jsonDataLevel = ["result", "payload"];
```

---

### 6. Call User's Serializer Function

**File:** `lib/src/models/single_response.dart`
**Line:** ~20

```dart
T object = create(json);  // Calls your Model.fromJson(json)
```

**Example:**
```dart
// User provides this:
serializer: (json) => Product.fromJson(json)

// SingleResponse calls it:
T object = create(json);  // → Product.fromJson(json)
```

---

### 7. Wrap in Response Object

**File:** `lib/src/models/single_response.dart`  
**Line:** ~28

```dart
return SingleResponse<T>(data: object);
```

**Result:** `SingleResponse<AuthResponse>` or `ListResponse<List<User>>`

---

### 8. Extract Data & Return Either

**File:** `lib/src/network/sc_network_api.dart`  
**Line:** ~389

```dart
result = Right<Failure, T>(
  SingleResponse<T>.fromJson(...).data  // ← Extracts .data property
);
```

**Success Path:**
```dart
return Right<Failure, AuthResponse>(authResponse);
```

**Failure Path:**
```dart
return Left<Failure, AuthResponse>(
  Failure(
    response.statusCode,     // HTTP status (e.g., 401, 500)
    statusAndMessage["status"] ?? 0,  // Internal status
    response.body,           // Error message
  )
);
```

**Final Return Type:** `Either<Failure, T>`

---

## Usage Example (Complete Flow)

```dart
// 1. Define response type
typedef LoginUserResponse = Either<Failure, AuthResponse>;

// 2. Make request
Future<LoginUserResponse> loginUser(User user) async {
  return SCNetworkApi().request<AuthResponse>(
    Method.POST,
    "auth/login",
    serializer: (json) => AuthResponse.fromJson(json),
    body: jsonEncode(user),
    enableLog: true,
  );
}

// 3. Handle response
final result = await loginUser(user);

result.fold(
  (failure) {
    // Left: Failure
    print('Error: ${failure.errorMessage}');
    print('HTTP Status: ${failure.statusCode}');
    print('Internal Status: ${failure.internalStatusCode}');
  },
  (authResponse) {
    // Right: Success
    print('Token: ${authResponse.token}');
    print('User ID: ${authResponse.userId}');
  },
);
```

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/src/network/sc_network_api.dart` | Main API client, request handling, response processing |
| `lib/src/models/base_response.dart` | Parent class with status field |
| `lib/src/models/single_response.dart` | Single object response parser |
| `lib/src/models/list_response.dart` | Array response parser |
| `lib/src/models/failure.dart` | Error representation |
| `lib/src/models/sc_cached_request.dart` | Offline queue request model |
| `lib/src/network/sc_multipart_request.dart` | File upload handler with progress |

## Summary

**Request Flow:**
```
Init → Header Building → request() → URI Building → Cache Check → 
_makeRequest() → HTTP Call → Response/Exception
```

**Response Flow (Success):**
```
HTTP Response → Status Validation → JSON Decode → Response Wrapper → 
User Serializer → Extract .data → Either.Right(T)
```

**Response Flow (Failure):**
```
Exception/Bad Status → Check Cache → Create Failure → 
Either.Left(Failure) → Retry?
```
