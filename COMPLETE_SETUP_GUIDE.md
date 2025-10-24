# Fineract OAuth2 Complete Setup Guide

## 📋 Mục lục
1. [Tổng quan hệ thống](#tổng-quan-hệ-thống)
2. [Setup dự án cho người mới](#setup-dự-án-cho-người-mới)
3. [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
4. [Scripts tự động hóa](#scripts-tự-động-hóa)
5. [Hướng dẫn kết nối Frontend](#hướng-dẫn-kết-nối-frontend)
6. [Troubleshooting](#troubleshooting)

---

## 🎯 Tổng quan hệ thống

### Hệ thống Fineract OAuth2 bao gồm:
- **Keycloak**: OAuth2 Server (Port 9000)
- **Fineract**: Resource Server (Port 8080) 
- **3 Scripts tự động**: Tạo Product, Client, Savings Account
- **Frontend Integration**: React Native/Web App

### Workflow hoàn chỉnh:
```
1. Setup Keycloak OAuth2 ✅
2. Tạo Savings Product ✅
3. Tạo và Activate Client ✅
4. Tạo Savings Account ✅
5. Kết nối Frontend ✅
```

---

## 🚀 Setup dự án cho người mới

### Yêu cầu hệ thống
- Docker & Docker Compose
- PowerShell (Windows) hoặc Bash (Linux/Mac)
- Git
- Java 17+ (để build từ source)

### 1. Clone và setup dự án

```bash
# Clone repository
git clone <repository-url>
cd fullstack-wallet/fineract

# Kiểm tra Docker
docker --version
docker-compose --version
```

### 2. Khởi động hệ thống

```bash
# Chạy Keycloak và Fineract
docker-compose up -d

# Đợi services khởi động (khoảng 2-3 phút)
docker-compose logs -f
```

### 3. Cấu hình Keycloak OAuth2

```bash
# Chạy script setup Keycloak
powershell -ExecutionPolicy Bypass -File .\02-setup-keycloak.ps1

# Hoặc setup thủ công:
# 1. Truy cập: http://localhost:9000
# 2. Login: admin/admin
# 3. Tạo realm "fineract"
# 4. Tạo user "mifos" với password "password"
# 5. Tạo client "community-app" với secret "real-client-secret-123"
```

### 4. Test OAuth2 Integration

```bash
# Test OAuth2 flow
powershell -ExecutionPolicy Bypass -File .\03-test-oauth.ps1
```

---

## 🏗️ Kiến trúc hệ thống

### Tổng quan

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Native  │──▶│    Keycloak     │───▶│    Fineract     │
│   (Frontend)    │    │   (OAuth Server)│    │(Resource Server)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   OAuth2 Flow   │    │   JWT Tokens    │    │   Business API  │
│   Authorization │    │   Authentication│    │   Data Access   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Components chi tiết

#### 1. **Keycloak (OAuth2 Server)**
- **Port**: 9000
- **Realm**: fineract
- **Client**: community-app
- **User**: mifos/password
- **JWT Issuer**: http://localhost:9000/realms/fineract

#### 2. **Fineract (Resource Server)**
- **Port**: 8080
- **OAuth2 Resource Server**: Enabled
- **JWT Validation**: Keycloak JWKS
- **Tenant**: default
- **API Base**: http://localhost:8080/fineract-provider/api/v1

#### 3. **OAuth2 Flow**
```
1. Client → Keycloak: Request token
2. Keycloak → Client: JWT token
3. Client → Fineract: API call với JWT
4. Fineract → Keycloak: Validate JWT
5. Fineract → Client: API response
```

### Security Configuration

#### Fineract Security Filters
```java
@ConditionalOnProperty("fineract.security.oauth.enabled")
public class AuthorizationServerConfig {
    // OAuth2 Resource Server
    .oauth2ResourceServer(resourceServer -> 
        resourceServer.jwt(jwt -> 
            jwt.decoder(jwtDecoder())
               .jwtAuthenticationConverter(authenticationConverter())))
    
    // Tenant Context Filter
    .addFilterAfter(tenantAwareAuthenticationFilter(), SecurityContextHolderFilter.class)
}
```

#### JWT Claims Mapping
- **Principal**: `preferred_username` (fallback: `sub`)
- **Authorities**: `realm_access.roles`
- **Tenant**: `tenant` claim (fallback: `Fineract-Platform-TenantId` header)

---

## 🤖 Scripts tự động hóa

### Script 1: Tạo Savings Product
**File**: `05-create-savings-product.ps1`

```powershell
# Chạy script tạo savings product
.\05-create-savings-product.ps1
```

**Chức năng**:
- Tạo savings product mới với cấu hình đầy đủ
- Sử dụng dữ liệu mẫu: Basic Savings Account
- **Lưu ý**: Product có thể đã tồn tại (lỗi 400 là bình thường)

**Dữ liệu tạo**:
```json
{
  "name": "Basic Savings Account",
  "shortName": "BSA", 
  "currencyCode": "USD",
  "nominalAnnualInterestRate": 5.0,
  "minRequiredOpeningBalance": 1000.0
}
```

### Script 2: Tạo và Activate Client
**File**: `06-create-client.ps1` hoặc `06-activate-existing-client.ps1`

```powershell
# Chạy script tạo client mới (có thể lỗi 400)
.\06-create-client.ps1

# Hoặc activate client hiện có (khuyến nghị)
.\06-activate-existing-client.ps1
```

**Chức năng**:
- Tạo client mới hoặc activate client hiện có
- Activate client sử dụng API: `POST /clients/{id}?command=activate`
- **Quan trọng**: Client phải được activate trước khi tạo savings account

**API Activate Client**:
```http
POST /clients/{clientId}?command=activate
Content-Type: application/json

{
  "activationDate": "2025-10-20",
  "locale": "vi", 
  "dateFormat": "yyyy-MM-dd"
}
```

### Script 3: Tạo Savings Account
**File**: `07-create-savings-account.ps1`

```powershell
# Chạy script tạo savings account
.\07-create-savings-account.ps1
```

**Chức năng**:
- Tự động tìm client active
- Tạo savings account với dữ liệu tối thiểu
- **✅ HOẠT ĐỘNG HOÀN HẢO** - Đã test thành công

**Dữ liệu tối thiểu**:
```json
{
  "clientId": 1,
  "productId": 1,
  "submittedOnDate": "20 October 2025",
  "locale": "en",
  "dateFormat": "dd MMMM yyyy"
}
```

### Workflow hoàn chỉnh

```bash
# 1. Setup OAuth2 (chỉ chạy 1 lần)
.\02-setup-keycloak.ps1
.\03-test-oauth.ps1

# 2. Tạo Product (có thể bỏ qua nếu đã có)
.\05-create-savings-product.ps1

# 3. Activate Client (bắt buộc)
.\06-activate-existing-client.ps1

# 4. Tạo Savings Account (mục tiêu chính)
.\07-create-savings-account.ps1
```

---

## 📱 Hướng dẫn kết nối Frontend

### React Native Integration

#### 1. **OAuth2 Flow cho React Native**

```javascript
// 1. Get OAuth2 token
const getOAuthToken = async () => {
  const response = await fetch('http://localhost:9000/realms/fineract/protocol/openid-connect/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      username: 'mifos',
      password: 'password',
      client_id: 'community-app',
      grant_type: 'password',
      client_secret: 'real-client-secret-123'
    })
  });
  
  const data = await response.json();
  return data.access_token;
};

// 2. Call Fineract API
const callFineractAPI = async (endpoint, token) => {
  const response = await fetch(`http://localhost:8080/fineract-provider/api/v1/${endpoint}`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Fineract-Platform-TenantId': 'default',
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }
  });
  
  return response.json();
};
```

#### 2. **API Endpoints Available**

```javascript
// GET APIs (Working)
const endpoints = {
  offices: '/offices',
  clients: '/clients',
  savingsAccounts: '/savingsaccounts',
  savingsProducts: '/savingsproducts',
  userDetails: '/v1/userdetails',
  configurations: '/configurations'
};

// POST APIs (Tested)
const postEndpoints = {
  // ✅ POST /savingsaccounts - Working
  // ✅ POST /clients/{id}?command=activate - Working
  // ❌ POST /clients - 400 Bad Request (business logic issue)
};
```

#### 3. **Tạo Savings Account từ Frontend**

```javascript
// Tạo savings account
const createSavingsAccount = async (clientId, productId, token) => {
  const savingsData = {
    clientId: clientId,
    productId: productId,
    submittedOnDate: "20 October 2025",
    locale: "en",
    dateFormat: "dd MMMM yyyy"
  };

  const response = await fetch('http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Fineract-Platform-TenantId': 'default',
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify(savingsData)
  });

  return response.json();
};
```

#### 4. **Complete React Native Example**

```javascript
import React, { useState, useEffect } from 'react';
import { View, Text, Button, Alert, FlatList } from 'react-native';

const FineractClient = () => {
  const [token, setToken] = useState(null);
  const [clients, setClients] = useState([]);
  const [savingsAccounts, setSavingsAccounts] = useState([]);

  useEffect(() => {
    authenticate();
  }, []);

  const authenticate = async () => {
    try {
      const token = await getOAuthToken();
      setToken(token);
      await loadData(token);
    } catch (error) {
      Alert.alert('Error', 'Authentication failed');
    }
  };

  const loadData = async (authToken) => {
    try {
      // Load clients
      const clientsData = await callFineractAPI('clients', authToken);
      setClients(clientsData.pageItems || []);

      // Load savings accounts
      const savingsData = await callFineractAPI('savingsaccounts', authToken);
      setSavingsAccounts(savingsData || []);
    } catch (error) {
      Alert.alert('Error', 'Failed to load data');
    }
  };

  const createSavingsAccount = async () => {
    try {
      const activeClient = clients.find(c => c.active === true);
      if (!activeClient) {
        Alert.alert('Error', 'No active client found');
        return;
      }

      const result = await createSavingsAccount(activeClient.id, 1, token);
      Alert.alert('Success', `Savings Account created: ${result.savingsId}`);
      await loadData(token); // Refresh data
    } catch (error) {
      Alert.alert('Error', 'Failed to create savings account');
    }
  };

  return (
    <View style={{ padding: 20 }}>
      <Text style={{ fontSize: 20, fontWeight: 'bold' }}>Fineract OAuth2 Client</Text>
      <Text>Token: {token ? 'Authenticated' : 'Not authenticated'}</Text>
      
      <Text style={{ fontSize: 16, marginTop: 20 }}>Clients ({clients.length})</Text>
      <FlatList
        data={clients}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <Text>{item.displayName} - {item.active ? 'Active' : 'Inactive'}</Text>
        )}
      />

      <Text style={{ fontSize: 16, marginTop: 20 }}>Savings Accounts ({savingsAccounts.length})</Text>
      <FlatList
        data={savingsAccounts}
        keyExtractor={(item) => item.id.toString()}
        renderItem={({ item }) => (
          <Text>Account {item.id} - Client: {item.clientName}</Text>
        )}
      />

      <Button title="Create Savings Account" onPress={createSavingsAccount} />
      <Button title="Refresh" onPress={() => authenticate()} />
    </View>
  );
};

export default FineractClient;
```

---

## ✅ Vấn đề đã giải quyết

### 1. **OAuth2 Integration**
- ✅ **Authentication**: JWT token validation với Keycloak
- ✅ **Authorization**: Role-based access control
- ✅ **Tenant Context**: Multi-tenant support
- ✅ **API Access**: GET /offices, GET /clients, etc.

### 2. **Savings Account Creation**
- ✅ **Client Activation**: API activate client hoạt động
- ✅ **Minimal Data**: Sử dụng dữ liệu tối thiểu thành công
- ✅ **API Endpoint**: POST /savingsaccounts hoạt động hoàn hảo
- ✅ **Response**: Trả về savingsId và resourceId

### 3. **Scripts Automation**
- ✅ **05-create-savings-product.ps1**: Tạo product (có thể bỏ qua)
- ✅ **06-activate-existing-client.ps1**: Activate client thành công
- ✅ **07-create-savings-account.ps1**: Tạo savings account thành công

### 4. **Configuration Issues**
- ✅ **SSL/HTTPS**: Disabled để tránh certificate issues
- ✅ **Port Configuration**: HTTP 8080, Keycloak 9000
- ✅ **Environment Variables**: Proper OAuth2 config
- ✅ **Docker Networking**: Container communication

---

## ⚠️ Vấn đề tồn tại

### 1. **POST /clients API**
- ❌ **Status**: 400 Bad Request
- ❌ **Error**: `PlatformApiDataValidationException: Validation errors exist`
- ❌ **Root Cause**: Business logic validation error (không liên quan OAuth)
- ❌ **Impact**: Không thể tạo client mới qua API
- ✅ **Workaround**: Sử dụng client hiện có và activate

### 2. **JWT Token Claims**
- ⚠️ **Tenant Claim**: JWT token không có `tenant` claim
- ⚠️ **Workaround**: Sử dụng `Fineract-Platform-TenantId` header
- ⚠️ **Impact**: Cần header cho mỗi request

### 3. **Production Readiness**
- ⚠️ **SSL**: Cần enable SSL cho production
- ⚠️ **Security**: Cần review security headers
- ⚠️ **Monitoring**: Cần thêm health checks
- ⚠️ **Scaling**: Cần test với multiple instances

---

## 🔧 Troubleshooting

### Common Issues

#### 1. **401 Unauthorized**
```bash
# Check token validity
curl -H "Authorization: Bearer <token>" http://localhost:8080/fineract-provider/api/v1/offices

# Check Keycloak connection
curl http://localhost:9000/realms/fineract/protocol/openid-connect/certs
```

#### 2. **403 Forbidden khi tạo Savings Account**
```bash
# Nguyên nhân: Client chưa được activate
# Giải pháp: Chạy script activate client
.\06-activate-existing-client.ps1
```

#### 3. **400 Bad Request khi tạo Client**
```bash
# Nguyên nhân: Business logic validation
# Giải pháp: Sử dụng client hiện có
.\06-activate-existing-client.ps1
```

#### 4. **Docker Issues**
```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs fineract
docker-compose logs keycloak

# Restart services
docker-compose restart
```

### Debug Commands

```bash
# Test OAuth2 flow
powershell -ExecutionPolicy Bypass -File .\03-test-oauth.ps1

# Test savings account creation
powershell -ExecutionPolicy Bypass -File .\07-create-savings-account.ps1

# Check client status
powershell -ExecutionPolicy Bypass -File .\06-activate-existing-client.ps1
```

### Lệnh chạy thường dùng

```bash
# Khởi động services
docker-compose up -d

# Xem logs
docker-compose logs -f fineract
docker-compose logs -f keycloak

# Restart services
docker-compose restart

# Dừng services
docker-compose down

# Build lại Fineract từ source
./gradlew clean build -x test
docker build -t fineract-local:dev .
```

---

## 📚 Resources

- [Fineract Documentation](https://fineract.apache.org/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [OAuth2 RFC](https://tools.ietf.org/html/rfc6749)
- [JWT RFC](https://tools.ietf.org/html/rfc7519)
- [Spring Security OAuth2](https://docs.spring.io/spring-security/reference/servlet/oauth2/index.html)

---

## 📞 Support

### Checklist khi gặp vấn đề:
1. ✅ Docker containers đang chạy
2. ✅ Keycloak accessible tại http://localhost:9000
3. ✅ Fineract accessible tại http://localhost:8080
4. ✅ OAuth2 token valid
5. ✅ Client đã được activate
6. ✅ Sử dụng dữ liệu tối thiểu cho savings account

### Workflow khuyến nghị:
```bash
# 1. Setup (chỉ chạy 1 lần)
.\02-setup-keycloak.ps1
.\03-test-oauth.ps1

# 2. Activate client (bắt buộc)
.\06-activate-existing-client.ps1

# 3. Tạo savings account (mục tiêu chính)
.\07-create-savings-account.ps1
```

**Happy Coding! 🚀**
