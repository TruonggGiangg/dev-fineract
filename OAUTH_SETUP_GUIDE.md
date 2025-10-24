# Fineract OAuth2 Setup Guide

## 📋 Mục lục
1. [Setup dự án cho người mới](#setup-dự-án-cho-người-mới)
2. [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
3. [Vấn đề đã giải quyết](#vấn-đề-đã-giải-quyết)
4. [Vấn đề tồn tại](#vấn-đề-tồn-tại)
5. [Hướng dẫn kết nối với Frontend](#hướng-dẫn-kết-nối-với-frontend)

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

### 2. Setup Keycloak OAuth2

```bash
# Chạy Keycloak và Fineract
docker-compose up -d

# Đợi services khởi động (khoảng 2-3 phút)
docker-compose logs -f
```

### 3. Cấu hình Keycloak

```bash
# Chạy script setup Keycloak
powershell -ExecutionPolicy Bypass -File .\setup-keycloak-basic.ps1

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
powershell -ExecutionPolicy Bypass -File .\test-oauth-simple.ps1

# Test tạo client (nếu cần)
powershell -ExecutionPolicy Bypass -File .\test-create-clients-oauth.ps1
```

### 5. Lệnh chạy thường dùng

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

 ./gradlew -x test :fineract-provider:jibDockerBuild -D"jib.to.image=fineract-local:dev"

docker build --no-cache -t fineract-local:dev .
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

## ✅ Vấn đề đã giải quyết

### 1. **OAuth2 Integration**
- ✅ **Authentication**: JWT token validation với Keycloak
- ✅ **Authorization**: Role-based access control
- ✅ **Tenant Context**: Multi-tenant support
- ✅ **API Access**: GET /offices, GET /clients, etc.

### 2. **Configuration Issues**
- ✅ **SSL/HTTPS**: Disabled để tránh certificate issues
- ✅ **Port Configuration**: HTTP 8080, Keycloak 9000
- ✅ **Environment Variables**: Proper OAuth2 config
- ✅ **Docker Networking**: Container communication

### 3. **Security Setup**
- ✅ **JWT Decoder**: Keycloak JWKS validation
- ✅ **Token Converter**: Custom FineractJwtAuthenticationTokenConverter
- ✅ **Tenant Filter**: TenantAwareAuthenticationFilter
- ✅ **Basic Auth**: Disabled khi OAuth2 enabled

### 4. **Development Workflow**
- ✅ **Build Process**: Gradle build với Jib
- ✅ **Docker Images**: Local build và deployment
- ✅ **Testing Scripts**: PowerShell automation
- ✅ **Debug Tools**: Log analysis và troubleshooting

---

## ⚠️ Vấn đề tồn tại

### 1. **POST /clients API**
- ❌ **Status**: 400 Bad Request
- ❌ **Error**: `PlatformApiDataValidationException: Validation errors exist`
- ❌ **Root Cause**: Business logic validation error (không liên quan OAuth)
- ❌ **Impact**: Không thể tạo client mới qua API

### 2. **JWT Token Claims**
- ⚠️ **Tenant Claim**: JWT token không có `tenant` claim
- ⚠️ **Workaround**: Sử dụng `Fineract-Platform-TenantId` header
- ⚠️ **Impact**: Cần header cho mỗi request

### 3. **Keycloak Configuration**
- ⚠️ **Mapper**: Tenant mapper đã tạo nhưng chưa hoạt động
- ⚠️ **Token Refresh**: Cần test refresh token flow
- ⚠️ **Scopes**: Cần kiểm tra scope permissions

### 4. **Production Readiness**
- ⚠️ **SSL**: Cần enable SSL cho production
- ⚠️ **Security**: Cần review security headers
- ⚠️ **Monitoring**: Cần thêm health checks
- ⚠️ **Scaling**: Cần test với multiple instances

---

## 📱 Hướng dẫn kết nối với Frontend

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
  userDetails: '/v1/userdetails',
  configurations: '/configurations'
};

// POST APIs (Limited)
const postEndpoints = {
  // ❌ POST /clients - 400 Bad Request
  // ✅ Other POST endpoints may work
};
```

#### 3. **Error Handling**

```javascript
const handleAPIError = (error) => {
  if (error.status === 401) {
    // Token expired - refresh or re-login
    return 'Authentication required';
  } else if (error.status === 400) {
    // Validation error
    return 'Invalid request data';
  } else if (error.status === 403) {
    // Permission denied
    return 'Access denied';
  }
  return 'Unknown error';
};
```

#### 4. **Complete Example**

```javascript
import React, { useState, useEffect } from 'react';
import { View, Text, Button, Alert } from 'react-native';

const FineractClient = () => {
  const [token, setToken] = useState(null);
  const [offices, setOffices] = useState([]);

  useEffect(() => {
    authenticate();
  }, []);

  const authenticate = async () => {
    try {
      const token = await getOAuthToken();
      setToken(token);
      await loadOffices(token);
    } catch (error) {
      Alert.alert('Error', 'Authentication failed');
    }
  };

  const loadOffices = async (authToken) => {
    try {
      const data = await callFineractAPI('offices', authToken);
      setOffices(data);
    } catch (error) {
      Alert.alert('Error', 'Failed to load offices');
    }
  };

  return (
    <View>
      <Text>Fineract OAuth2 Client</Text>
      <Text>Token: {token ? 'Authenticated' : 'Not authenticated'}</Text>
      <Text>Offices: {offices.length}</Text>
      <Button title="Refresh" onPress={() => authenticate()} />
    </View>
  );
};

export default FineractClient;
```

### Configuration cho Production

#### 1. **Environment Variables**
```bash
# Keycloak
KEYCLOAK_URL=https://your-keycloak.com
KEYCLOAK_REALM=your-realm
KEYCLOAK_CLIENT_ID=your-client-id
KEYCLOAK_CLIENT_SECRET=your-client-secret

# Fineract
FINERACT_URL=https://your-fineract.com
FINERACT_TENANT_ID=your-tenant
```

#### 2. **Security Considerations**
- ✅ **HTTPS**: Enable SSL/TLS
- ✅ **Token Storage**: Secure token storage
- ✅ **Token Refresh**: Implement refresh mechanism
- ✅ **Error Handling**: Proper error handling
- ✅ **Validation**: Input validation

#### 3. **Testing Checklist**
- [ ] OAuth2 authentication
- [ ] JWT token validation
- [ ] API endpoints access
- [ ] Error handling
- [ ] Token refresh
- [ ] Network connectivity
- [ ] Security headers

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

#### 2. **400 Bad Request**
```bash
# Check request format
# Check required headers
# Check tenant context
```

#### 3. **Docker Issues**
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
powershell -ExecutionPolicy Bypass -File .\test-oauth-simple.ps1

# Check tenant context
powershell -ExecutionPolicy Bypass -File .\test-tenant-context.ps1

# Debug client creation
powershell -ExecutionPolicy Bypass -File .\test-client-with-tenant.ps1
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

Nếu gặp vấn đề, hãy kiểm tra:
1. Docker containers đang chạy
2. Keycloak accessible tại http://localhost:9000
3. Fineract accessible tại http://localhost:8080
4. OAuth2 token valid
5. Tenant context đúng

**Happy Coding! 🚀**
