# 🏦 HƯỚNG DẪN SỬ DỤNG FINERACT CHO CLIENT

## 📋 TỔNG QUAN HỆ THỐNG

### **Kiến trúc hệ thống**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Keycloak      │    │   Fineract      │    │   MariaDB       │
│   (OAuth2)      │◄──►│   (Core API)    │◄──►│   (Database)    │
│   Port: 9000    │    │   Port: 8080    │    │   Port: 3306    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Thông tin kết nối**
- **Keycloak URL**: `http://localhost:9000`
- **Fineract URL**: `http://localhost:8080/fineract-provider/api/v1`
- **Tenant ID**: `default`
- **Realm**: `fineract`
- **Client ID**: `community-app`
- **Client Secret**: `real-client-secret-123`

## 🔐 XÁC THỰC VÀ PHÂN QUYỀN

### **1. OAuth2 Authentication Flow**

#### **Bước 1: Lấy Access Token**
```http
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

username=mifos&password=password&client_id=community-app&grant_type=password&client_secret=real-client-secret-123
```

#### **Bước 2: Sử dụng Token trong API calls**
```http
GET http://localhost:8080/fineract-provider/api/v1/offices?tenantIdentifier=default
Authorization: Bearer {access_token}
Fineract-Platform-TenantId: default
Content-Type: application/json
```

### **2. Phân quyền trong Fineract**

#### **User Roles & Permissions**
- **User**: `mifos` (đã tạo sẵn)
- **Password**: `password`
- **Roles**: Được map từ Keycloak realm `fineract`
- **Permissions**: Được quản lý trong Fineract database

#### **Cấu trúc phân quyền**
```
Keycloak Realm (fineract)
├── User: mifos
├── Client: community-app
└── Roles: [mapped to Fineract permissions]

Fineract Database
├── m_appuser (users)
├── m_role (roles)
├── m_permission (permissions)
├── m_role_permission (role-permission mapping)
└── m_appuser_role (user-role mapping)
```

## 🏢 QUẢN LÝ OFFICES

### **Lấy danh sách Offices**
```http
GET /offices?tenantIdentifier=default
```

**Response:**
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

## 👥 QUẢN LÝ CLIENTS

### **1. Tạo Client mới**
```http
POST /clients?tenantIdentifier=default
Content-Type: application/json

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

### **2. Activate Client**
```http
POST /clients/{clientId}?command=activate&tenantIdentifier=default
Content-Type: application/json

{
  "activationDate": "2025-10-20",
  "locale": "vi",
  "dateFormat": "yyyy-MM-dd"
}
```

### **3. Lấy thông tin Client**
```http
GET /clients/{clientId}?tenantIdentifier=default
```

## 💰 QUẢN LÝ SAVINGS PRODUCTS

### **1. Tạo Savings Product**
```http
POST /savingsproducts?tenantIdentifier=default
Content-Type: application/json

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

### **2. Lấy danh sách Products**
```http
GET /savingsproducts?tenantIdentifier=default
```

## 🏦 QUẢN LÝ SAVINGS ACCOUNTS

### **1. Tạo Savings Account**
```http
POST /savingsaccounts?tenantIdentifier=default
Content-Type: application/json

{
  "submittedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "productId": 1,
  "clientId": 1,
  "locale": "en"
}
```

### **2. Approve Savings Account**
```http
POST /savingsaccounts/{accountId}?command=approve&tenantIdentifier=default
Content-Type: application/json

{
  "approvedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en"
}
```

### **3. Activate Savings Account**
```http
POST /savingsaccounts/{accountId}?command=activate&tenantIdentifier=default
Content-Type: application/json

{
  "activatedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en"
}
```

## 🔧 SCRIPTS TỰ ĐỘNG HÓA

### **1. Tạo Savings Product**
```powershell
.\05-create-savings-product.ps1
```

### **2. Tạo và Activate Client**
```powershell
.\06-create-client.ps1
```

### **3. Tạo Savings Account**
```powershell
.\07-create-savings-account.ps1
```

### **4. Activate Client hiện có**
```powershell
.\06-activate-existing-client.ps1
```

## 📱 TÍCH HỢP VÀO ỨNG DỤNG

### **1. React Native Integration**

#### **OAuth2Service.js**
```javascript
class OAuth2Service {
  static async getToken(username, password) {
    const response = await fetch('http://localhost:9000/realms/fineract/protocol/openid-connect/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: `username=${username}&password=${password}&client_id=community-app&grant_type=password&client_secret=real-client-secret-123`
    });
    
    return await response.json();
  }
}
```

#### **FineractAPIService.js**
```javascript
class FineractAPIService {
  static async callAPI(endpoint, method = 'GET', data = null, token) {
    const response = await fetch(`http://localhost:8080/fineract-provider/api/v1${endpoint}?tenantIdentifier=default`, {
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Fineract-Platform-TenantId': 'default',
        'Accept': 'application/json'
      },
      body: data ? JSON.stringify(data) : null
    });
    
    return await response.json();
  }
}
```

### **2. Workflow hoàn chỉnh**

#### **Bước 1: Authentication**
```javascript
const tokenData = await OAuth2Service.getToken('mifos', 'password');
const accessToken = tokenData.access_token;
```

#### **Bước 2: Tạo Client**
```javascript
const clientData = {
  officeId: 1,
  legalFormId: 1,
  firstname: "John",
  lastname: "Doe",
  dateOfBirth: "1990-01-01",
  locale: "en",
  dateFormat: "yyyy-MM-dd",
  active: false
};

const client = await FineractAPIService.callAPI('/clients', 'POST', clientData, accessToken);
```

#### **Bước 3: Activate Client**
```javascript
const activateData = {
  activationDate: "2025-10-20",
  locale: "vi",
  dateFormat: "yyyy-MM-dd"
};

await FineractAPIService.callAPI(`/clients/${client.clientId}?command=activate`, 'POST', activateData, accessToken);
```

#### **Bước 4: Tạo Savings Account**
```javascript
const savingsData = {
  submittedOnDate: "20 October 2025",
  dateFormat: "dd MMMM yyyy",
  productId: 1,
  clientId: client.clientId,
  locale: "en"
};

const savingsAccount = await FineractAPIService.callAPI('/savingsaccounts', 'POST', savingsData, accessToken);
```

## 🚨 XỬ LÝ LỖI THƯỜNG GẶP

### **1. Lỗi 401 Unauthorized**
- **Nguyên nhân**: Token hết hạn hoặc không hợp lệ
- **Giải pháp**: Lấy token mới từ Keycloak

### **2. Lỗi 403 Forbidden**
- **Nguyên nhân**: Client chưa được activate
- **Giải pháp**: Activate client trước khi tạo savings account

### **3. Lỗi 400 Bad Request**
- **Nguyên nhân**: Dữ liệu gửi đi không đúng format
- **Giải pháp**: Kiểm tra lại JSON payload và required fields

### **4. Lỗi 404 Not Found**
- **Nguyên nhân**: Endpoint không tồn tại hoặc resource không tìm thấy
- **Giải pháp**: Kiểm tra URL và resource ID

## 📊 MONITORING VÀ DEBUG

### **1. Kiểm tra trạng thái hệ thống**
```bash
# Kiểm tra Docker containers
docker-compose ps

# Kiểm tra logs
docker-compose logs fineract
docker-compose logs keycloak
```

### **2. Test kết nối**
```powershell
# Test Keycloak
curl http://localhost:9000/realms/fineract

# Test Fineract
curl http://localhost:8080/fineract-provider/api/v1/offices
```

### **3. Debug OAuth2 Flow**
```powershell
# Test lấy token
.\test-simple.ps1
```

## 🔒 BẢO MẬT

### **1. Token Management**
- Token có thời hạn (thường 1 giờ)
- Cần refresh token khi hết hạn
- Không lưu token trong localStorage

### **2. API Security**
- Luôn sử dụng HTTPS trong production
- Validate tất cả input data
- Implement rate limiting

### **3. Database Security**
- Sử dụng connection pooling
- Encrypt sensitive data
- Regular backup

## 📞 HỖ TRỢ

### **Tài liệu tham khảo**
- [Fineract API Documentation](https://demo.mifos.io/api-docs/apiLive.htm)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [OAuth2 Specification](https://tools.ietf.org/html/rfc6749)

### **Liên hệ hỗ trợ**
- **Email**: support@example.com
- **Phone**: +84 123 456 789
- **Documentation**: [Internal Wiki](https://wiki.example.com)

---

**Lưu ý**: Hướng dẫn này dành cho môi trường development. Trong production, cần cấu hình bảo mật và monitoring phù hợp.
