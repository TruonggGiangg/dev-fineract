# 🚀 HƯỚNG DẪN TEST API VỚI POSTMAN

## 📋 TỔNG QUAN

Hướng dẫn này sẽ giúp bạn test toàn bộ Fineract API với OAuth2 authentication sử dụng Postman.

### **Thông tin hệ thống**
- **Keycloak**: `http://localhost:9000`
- **Fineract**: `http://localhost:8080/fineract-provider/api/v1`
- **Tenant**: `default`
- **Realm**: `fineract`
- **Client**: `community-app`
- **User**: `mifos/password`

## 🔐 BƯỚC 1: SETUP POSTMAN ENVIRONMENT

### **1.1 Tạo Environment**
1. Mở Postman
2. Click **Environments** → **Create Environment**
3. Đặt tên: `Fineract Local`
4. Thêm các variables:

| Variable | Initial Value | Current Value |
|----------|---------------|---------------|
| `keycloak_url` | `http://localhost:9000` | `http://localhost:9000` |
| `fineract_url` | `http://localhost:8080/fineract-provider/api/v1` | `http://localhost:8080/fineract-provider/api/v1` |
| `tenant_id` | `default` | `default` |
| `realm` | `fineract` | `fineract` |
| `client_id` | `community-app` | `community-app` |
| `client_secret` | `real-client-secret-123` | `real-client-secret-123` |
| `username` | `mifos` | `mifos` |
| `password` | `password` | `password` |
| `access_token` | `` | `` |
| `client_id_created` | `` | `` |
| `savings_product_id` | `` | `` |
| `savings_account_id` | `` | `` |

### **1.2 Chọn Environment**
- Click dropdown **Environments** ở góc trên bên phải
- Chọn **Fineract Local**

## 🔑 BƯỚC 2: LẤY OAUTH2 TOKEN

### **2.1 Tạo Request lấy Token**
1. **Method**: `POST`
2. **URL**: `{{keycloak_url}}/realms/{{realm}}/protocol/openid-connect/token`
3. **Headers**:
   ```
   Content-Type: application/x-www-form-urlencoded
   ```
4. **Body** (x-www-form-urlencoded):
   ```
   username={{username}}
   password={{password}}
   client_id={{client_id}}
   grant_type=password
   client_secret={{client_secret}}
   ```

### **2.2 Test và lưu Token**
1. Click **Send**
2. Kiểm tra response có `access_token`
3. Copy `access_token` value
4. Vào **Environments** → **Fineract Local**
5. Paste vào `access_token` variable

## 🏢 BƯỚC 3: TEST FINERACT APIS

### **3.1 Test Health Check**
**Request**: `GET {{fineract_url}}/offices?tenantIdentifier={{tenant_id}}`

**Headers**:
```
Authorization: Bearer {{access_token}}
Fineract-Platform-TenantId: {{tenant_id}}
Content-Type: application/json
Accept: application/json
```

**Expected Response**: Danh sách offices

### **3.2 Lấy danh sách Offices**
**Request**: `GET {{fineract_url}}/offices?tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Expected Response**:
```json
{
  "id": 1,
  "name": "Head Office",
  "nameDecorated": "Head Office",
  "externalId": "1",
  "openingDate": [2025, 1, 1],
  "hierarchy": ".",
  "status": "Active"
}
```

## 👥 BƯỚC 4: TẠO VÀ QUẢN LÝ CLIENT

### **4.1 Tạo Client mới**
**Request**: `POST {{fineract_url}}/clients?tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Body** (raw JSON):
```json
{
  "officeId": 1,
  "legalFormId": 1,
  "firstname": "John",
  "lastname": "Doe",
  "dateOfBirth": "1990-01-01",
  "locale": "en",
  "dateFormat": "yyyy-MM-dd",
  "active": false
}
```

**Expected Response**:
```json
{
  "officeId": 1,
  "clientId": 1,
  "resourceId": 1
}
```

**Lưu `clientId` vào variable `client_id_created`**

### **4.2 Activate Client**
**Request**: `POST {{fineract_url}}/clients/{{client_id_created}}?command=activate&tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Body** (raw JSON):
```json
{
  "activationDate": "2025-10-20",
  "locale": "vi",
  "dateFormat": "yyyy-MM-dd"
}
```

**Expected Response**: Status 200 OK

### **4.3 Lấy thông tin Client**
**Request**: `GET {{fineract_url}}/clients/{{client_id_created}}?tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Expected Response**: Thông tin chi tiết client

## 💰 BƯỚC 5: TẠO SAVINGS PRODUCT

### **5.1 Tạo Savings Product**
**Request**: `POST {{fineract_url}}/savingsproducts?tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Body** (raw JSON):
```json
{
  "name": "Passbook Savings",
  "shortName": "PBSV",
  "description": "Daily compounding using Daily Balance, 5% per year, 365 days in year",
  "currencyCode": "USD",
  "digitsAfterDecimal": 2,
  "inMultiplesOf": 0,
  "nominalAnnualInterestRate": 5,
  "interestCompoundingPeriodType": 1,
  "interestPostingPeriodType": 4,
  "interestCalculationType": 1,
  "interestCalculationDaysInYearType": 365,
  "accountingRule": 1,
  "enforceMinRequiredBalance": false,
  "isDormancyTrackingActive": false,
  "locale": "en",
  "withHoldTax": false,
  "withdrawalFeeForTransfers": false,
  "allowOverdraft": false,
  "charges": []
}
```

**Expected Response**:
```json
{
  "resourceId": 1
}
```

**Lưu `resourceId` vào variable `savings_product_id`**

### **5.2 Lấy danh sách Savings Products**
**Request**: `GET {{fineract_url}}/savingsproducts?tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Expected Response**: Danh sách products

## 🏦 BƯỚC 6: TẠO SAVINGS ACCOUNT

### **6.1 Tạo Savings Account**
**Request**: `POST {{fineract_url}}/savingsaccounts?tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Body** (raw JSON):
```json
{
  "submittedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "productId": {{savings_product_id}},
  "clientId": {{client_id_created}},
  "locale": "en"
}
```

**Expected Response**:
```json
{
  "officeId": 1,
  "clientId": 1,
  "savingsId": 2,
  "resourceId": 2,
  "gsimId": 0
}
```

**Lưu `savingsId` vào variable `savings_account_id`**

### **6.2 Approve Savings Account**
**Request**: `POST {{fineract_url}}/savingsaccounts/{{savings_account_id}}?command=approve&tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Body** (raw JSON):
```json
{
  "approvedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en"
}
```

**Expected Response**: Status 200 OK

### **6.3 Activate Savings Account**
**Request**: `POST {{fineract_url}}/savingsaccounts/{{savings_account_id}}?command=activate&tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Body** (raw JSON):
```json
{
  "activatedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en"
}
```

**Expected Response**: Status 200 OK

### **6.4 Lấy thông tin Savings Account**
**Request**: `GET {{fineract_url}}/savingsaccounts/{{savings_account_id}}?tenantIdentifier={{tenant_id}}`

**Headers**: (giống như trên)

**Expected Response**: Thông tin chi tiết savings account

## 🔄 BƯỚC 7: TẠO POSTMAN COLLECTION

### **7.1 Tạo Collection**
1. Click **Collections** → **Create Collection**
2. Đặt tên: `Fineract API Tests`
3. Thêm description: `Complete Fineract API testing with OAuth2`

### **7.2 Tạo Folder Structure**
```
Fineract API Tests/
├── 01. Authentication/
│   └── Get OAuth2 Token
├── 02. Health Checks/
│   └── Test Fineract Health
├── 03. Offices/
│   └── Get Offices
├── 04. Clients/
│   ├── Create Client
│   ├── Activate Client
│   └── Get Client Details
├── 05. Savings Products/
│   ├── Create Savings Product
│   └── Get Savings Products
└── 06. Savings Accounts/
    ├── Create Savings Account
    ├── Approve Savings Account
    ├── Activate Savings Account
    └── Get Savings Account Details
```

### **7.3 Tạo Pre-request Scripts**

#### **Cho tất cả requests (trừ Get Token)**
```javascript
// Kiểm tra access_token
if (!pm.environment.get("access_token")) {
    console.log("No access token found. Please run 'Get OAuth2 Token' first.");
    pm.test("Access token exists", function () {
        pm.expect(pm.environment.get("access_token")).to.not.be.undefined;
    });
}
```

#### **Cho Get OAuth2 Token**
```javascript
// Lưu access_token vào environment
pm.test("Token received", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.access_token).to.not.be.undefined;
    pm.environment.set("access_token", jsonData.access_token);
});
```

#### **Cho Create Client**
```javascript
// Lưu clientId vào environment
pm.test("Client created", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.clientId).to.not.be.undefined;
    pm.environment.set("client_id_created", jsonData.clientId);
});
```

#### **Cho Create Savings Product**
```javascript
// Lưu productId vào environment
pm.test("Product created", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.resourceId).to.not.be.undefined;
    pm.environment.set("savings_product_id", jsonData.resourceId);
});
```

#### **Cho Create Savings Account**
```javascript
// Lưu savingsId vào environment
pm.test("Savings Account created", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.savingsId).to.not.be.undefined;
    pm.environment.set("savings_account_id", jsonData.savingsId);
});
```

## 🧪 BƯỚC 8: TẠO TESTS

### **8.1 Tests cho Get OAuth2 Token**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has access_token", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.access_token).to.not.be.undefined;
    pm.expect(jsonData.token_type).to.eql("Bearer");
});
```

### **8.2 Tests cho Health Check**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response has offices", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData).to.be.an('array');
    pm.expect(jsonData.length).to.be.greaterThan(0);
});
```

### **8.3 Tests cho Create Client**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Client created successfully", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.clientId).to.not.be.undefined;
    pm.expect(jsonData.resourceId).to.not.be.undefined;
});
```

### **8.4 Tests cho Activate Client**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Client activated", function () {
    pm.expect(pm.response.text).to.include("activated");
});
```

### **8.5 Tests cho Create Savings Product**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Product created successfully", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.resourceId).to.not.be.undefined;
});
```

### **8.6 Tests cho Create Savings Account**
```javascript
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Savings Account created successfully", function () {
    var jsonData = pm.response.json();
    pm.expect(jsonData.savingsId).to.not.be.undefined;
    pm.expect(jsonData.resourceId).to.not.be.undefined;
});
```

## 🚀 BƯỚC 9: CHẠY COLLECTION

### **9.1 Chạy toàn bộ Collection**
1. Click vào **Fineract API Tests** collection
2. Click **Run** button
3. Chọn **Fineract Local** environment
4. Click **Run Fineract API Tests**

### **9.2 Chạy từng folder**
1. Click vào folder (ví dụ: **04. Clients**)
2. Click **Run** button
3. Chọn environment và chạy

### **9.3 Chạy từng request**
1. Click vào request
2. Click **Send**
3. Kiểm tra response và tests

## 🔍 BƯỚC 10: DEBUG VÀ TROUBLESHOOTING

### **10.1 Kiểm tra Environment Variables**
```javascript
// Thêm vào Pre-request Script
console.log("Keycloak URL:", pm.environment.get("keycloak_url"));
console.log("Fineract URL:", pm.environment.get("fineract_url"));
console.log("Access Token:", pm.environment.get("access_token"));
```

### **10.2 Kiểm tra Response Headers**
```javascript
// Thêm vào Tests
pm.test("Response has correct headers", function () {
    pm.expect(pm.response.headers.get("Content-Type")).to.include("application/json");
});
```

### **10.3 Kiểm tra Response Time**
```javascript
// Thêm vào Tests
pm.test("Response time is less than 5000ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(5000);
});
```

## 📊 BƯỚC 11: MONITORING VÀ REPORTING

### **11.1 Tạo Collection Runner**
1. Click **Collections** → **Fineract API Tests**
2. Click **Run** button
3. Chọn **Fineract Local** environment
4. Click **Run** để chạy tất cả tests

### **11.2 Export Test Results**
1. Sau khi chạy xong, click **Export Results**
2. Chọn format: **JSON** hoặc **HTML**
3. Lưu file để báo cáo

### **11.3 Newman CLI (Optional)**
```bash
# Cài đặt Newman
npm install -g newman

# Chạy collection từ command line
newman run "Fineract API Tests.postman_collection.json" -e "Fineract Local.postman_environment.json"
```

## 🎯 BƯỚC 12: BEST PRACTICES

### **12.1 Environment Management**
- Tạo separate environments cho dev/staging/prod
- Không commit sensitive data vào git
- Sử dụng variables thay vì hardcode values

### **12.2 Request Organization**
- Đặt tên request rõ ràng
- Thêm description cho mỗi request
- Sử dụng folder structure hợp lý

### **12.3 Test Coverage**
- Test cả success và error cases
- Validate response structure
- Check response time
- Verify business logic

### **12.4 Documentation**
- Thêm comments vào scripts
- Document expected responses
- Tạo README cho collection

## 🚨 XỬ LÝ LỖI THƯỜNG GẶP

### **Lỗi 401 Unauthorized**
- Kiểm tra access_token có đúng không
- Chạy lại "Get OAuth2 Token" request
- Kiểm tra username/password

### **Lỗi 403 Forbidden**
- Kiểm tra client đã được activate chưa
- Kiểm tra user có quyền thực hiện action không

### **Lỗi 400 Bad Request**
- Kiểm tra JSON format
- Kiểm tra required fields
- Kiểm tra data types

### **Lỗi 404 Not Found**
- Kiểm tra URL có đúng không
- Kiểm tra resource ID có tồn tại không
- Kiểm tra tenant identifier

---

**Lưu ý**: Hướng dẫn này dành cho môi trường development. Trong production, cần cấu hình bảo mật và monitoring phù hợp.
