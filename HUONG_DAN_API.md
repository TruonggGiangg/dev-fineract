# HƯỚNG DẪN API - LUỒNG ĐĂNG KÝ VÀ ĐĂNG NHẬP

## Cấu hình hệ thống

**Keycloak:**
- URL: `http://10.10.2.221:9000`
- Realm: `fineract`
- Client ID: `community-app`
- Client Secret: `real-client-secret-123`

**Fineract:**
- URL: `http://10.10.2.221:8080/fineract-provider/api/v1`
- Tenant ID: `default`
- Admin User: `mifos/password`

---

## BƯỚC 0: TẠO CLIENT (KHÁCH HÀNG)
Bước A: Lấy OAuth2 Access Token từ Keycloak
URL: http://10.10.2.221:9000/realms/fineract/protocol/openid-connect/token
Method: POST
Content-Type: application/x-www-form-urlencoded
Body (form data):
username: testuser
password: TestClient123@
client_id: community-app
client_secret: real-client-secret-123
grant_type: password
Response (chính cần):
access_token: JWT dùng để gọi Fineract
refresh_token: dùng để xin access token mới khi hết hạn
expires_in: số giây còn hạn của access_token
Bước B: Gọi Fineract API bằng Access Token
Luôn thêm headers:
Authorization: Bearer {access_token}
Fineract-Platform-TenantId: default
Accept: application/json
Content-Type: application/json (nếu có body)
Ví dụ headers hợp lệ khi GET:
Authorization: Bearer eyJhbGciOi...
Fineract-Platform-TenantId: default
Accept: application/json
Lỗi thường gặp:
401: Token hết hạn/không hợp lệ → dùng refresh_token để lấy token mới.
403: Thiếu quyền hoặc client chưa active.
404: Sai endpoint hoặc thiếu tenantIdentifier query nếu API yêu cầu.
Bước C: Refresh Token khi Access Token hết hạn
URL: http://10.10.2.221:9000/realms/fineract/protocol/openid-connect/token
Method: POST
Content-Type: application/x-www-form-urlencoded
Body (form data):
grant_type: refresh_token
client_id: community-app
client_secret: real-client-secret-123
refresh_token: {refresh_token}
Response: Trả về access_token mới và (thường) refresh_token mới.
## BƯỚC 1: TẠO CLIENT (KHÁCH HÀNG)

### 1.1 Tạo Client mới

**Endpoint:** `POST /clients`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

**Request Body:**
```json
{
  "firstname": "Nguyen",
  "lastname": "Test",
  "mobileNo": "0123456789",
  "externalId": "testuser",
  "officeId": 1,
  "legalFormId": 1,
  "active": false,
  "submittedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en_US"
}
```

**Response:**
```json
{
  "clientId": 32,
  "resourceId": 32,
  "officeId": 1
}
```

### 1.2 Activate Client

**Endpoint:** `POST /clients/{clientId}?command=activate`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

**Request Body:**
```json
{
  "activationDate": "2025-10-20",
  "locale": "en",
  "dateFormat": "yyyy-MM-dd"
}
```

**Response:**
```json
{
  "resourceId": 32,
  "changes": {
    "status": {
      "id": 300,
      "code": "clientStatusType.active",
      "value": "Active"
    }
  }
}
```

---

## BƯỚC 2: TẠO SAVINGS ACCOUNT (CHỈ CHO MERCHANT)

### 2.1 Tạo Savings Account

**Endpoint:** `POST /savingsaccounts`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

**Request Body:**
```json
{
  "clientId": 32,
  "productId": 1,
  "nominalAnnualInterestRate": 5.0,
  "minRequiredOpeningBalance": 0,
  "allowOverdraft": false,
  "externalId": "testuser-1729425600000",
  "submittedOnDate": "20 October 2025",
  "locale": "en_US",
  "dateFormat": "dd MMMM yyyy"
}
```

**Response:**
```json
{
  "savingsId": 6,
  "resourceId": 6,
  "clientId": 32
}
```

### 2.2 Approve Savings Account

**Endpoint:** `POST /savingsaccounts/{savingsId}?command=approve`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

**Request Body:**
```json
{
  "approvedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en_US"
}
```

### 2.3 Activate Savings Account

**Endpoint:** `POST /savingsaccounts/{savingsId}?command=activate`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

**Request Body:**
```json
{
  "activatedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en_US"
}
```

### 2.4 Lấy thông tin Savings Account

**Endpoint:** `GET /savingsaccounts/{savingsId}`

**Headers:**
```
Authorization: Bearer {admin_token}
Fineract-Platform-TenantId: default
```

**Response:**
```json
{
  "id": 6,
  "accountNo": "000000006",
  "status": {
    "id": 100,
    "code": "savingsAccountStatusType.active",
    "value": "Active"
  },
  "accountBalance": 0.00
}
```

---

## BƯỚC 3: TẠO USER TRÊN FINERACT

### 3.1 Tạo User

**Endpoint:** `POST /users`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

**Request Body:**
```json
{
  "firstname": "Nguyen",
  "lastname": "Test",
  "email": "test@example.com",
  "password": "TestClient123@",
  "repeatPassword": "TestClient123@",
  "officeId": 1,
  "roles": [1, 2],
  "sendPasswordToEmail": false,
  "isSelfServiceUser": true,
  "username": "testuser"
}
```

**Response:**
```json
{
  "resourceId": 8,
  "officeId": 1
}
```

---

## BƯỚC 4: LINK CLIENT VỚI USER

### 4.1 Link Client với User

**Endpoint:** `PUT /users/{userId}`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

**Request Body:**
```json
{
  "clients": [32]
}
```

**Response:**
```json
{
  "resourceId": 8,
  "changes": {
    "clients": [32]
  }
}
```

---

## BƯỚC 5: TẠO USER TRÊN KEYCLOAK

### 5.1 Lấy Admin Token

**Endpoint:** `POST /realms/master/protocol/openid-connect/token`

**Request Body (form-data):**
```
client_id: admin-cli
username: admin
password: admin
grant_type: password
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6IC...",
  "token_type": "Bearer",
  "expires_in": 60
}
```

### 5.2 Tạo User trong Keycloak

**Endpoint:** `POST /admin/realms/fineract/users`

**Headers:**
```
Authorization: Bearer {admin_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "username": "testuser",
  "enabled": true,
  "firstName": "Nguyen",
  "lastName": "Test",
  "email": "test@example.com",
  "emailVerified": true,
  "credentials": [
    {
      "type": "password",
      "value": "TestClient123@",
      "temporary": false
    }
  ]
}
```

**Response:** `201 Created` (no body)

---

## BƯỚC 6: ĐĂNG NHẬP VÀ LẤY TOKEN

### 6.1 Lấy OAuth2 Token

**Endpoint:** `POST /realms/fineract/protocol/openid-connect/token`

**Request Body (form-data):**
```
username: testuser
password: TestClient123@
client_id: community-app
grant_type: password
client_secret: real-client-secret-123
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6IC...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6IC...",
  "token_type": "Bearer",
  "scope": "profile email"
}
```

### 6.2 Test Fineract API với Token

**Endpoint:** `GET /v1/userdetails`

**Headers:**
```
Authorization: Bearer {access_token}
Fineract-Platform-TenantId: default
```

**Response:**
```json
{
  "username": "testuser",
  "officeName": "Head Office",
  "roles": ["Mobile Wallet", "Super User"]
}
```

### 6.3 Test Self-Service Authentication

**Endpoint:** `POST /v1/self/authentication`

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

**Request Body:**
```json
{
  "username": "testuser",
  "password": "TestClient123@"
}
```

**Response:**
```json
{
  "authenticated": true,
  "username": "testuser"
}
```

---

## REFRESH TOKEN

### Khi Token hết hạn

**Endpoint:** `POST /realms/fineract/protocol/openid-connect/token`

**Request Body (form-data):**
```
grant_type: refresh_token
client_id: community-app
client_secret: real-client-secret-123
refresh_token: {refresh_token}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6IC...",
  "expires_in": 300,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6IC...",
  "token_type": "Bearer"
}
```

---

## CÁC API ENDPOINTS CẦN TOKEN

### Thông tin User
- `GET /v1/userdetails` - Thông tin user hiện tại
- `GET /users/{id}` - Thông tin user theo ID

### Quản lý Client
- `GET /clients` - Danh sách clients
- `GET /clients/{id}` - Thông tin client
- `POST /clients` - Tạo client mới
- `PUT /clients/{id}` - Cập nhật client

### Quản lý Savings Account
- `GET /savingsaccounts` - Danh sách savings accounts
- `GET /savingsaccounts/{id}` - Thông tin savings account
- `POST /savingsaccounts` - Tạo savings account mới
- `POST /savingsaccounts/{id}?command=approve` - Duyệt savings account
- `POST /savingsaccounts/{id}?command=activate` - Kích hoạt savings account

### Self-Service
- `POST /v1/self/authentication` - Xác thực self-service

---

## XỬ LÝ LỖI

### 400 Bad Request
- Kiểm tra dữ liệu đầu vào
- Đảm bảo các trường bắt buộc
- Kiểm tra format ngày tháng

### 401 Unauthorized
- Token hết hạn hoặc không hợp lệ
- User chưa được tạo trong Keycloak
- Sai credentials

### 403 Forbidden
- Client chưa được activate
- User không có quyền
- Kiểm tra roles và permissions

### 404 Not Found
- Endpoint không tồn tại
- Resource không tìm thấy
- Kiểm tra URL và parameters

### 409 Conflict
- Duplicate externalId
- User đã tồn tại
- Kiểm tra tính duy nhất

---

## LƯU Ý QUAN TRỌNG

1. **Thứ tự thực hiện:** Activate client trước khi tạo savings account
2. **Token management:** Access token có thời hạn 5 phút, refresh token 30 phút
3. **Headers bắt buộc:** Luôn include `Fineract-Platform-TenantId: default`
4. **Self-service:** User đăng nhập qua Keycloak, không phải admin API
5. **Error handling:** Luôn kiểm tra response status và xử lý lỗi
