# 🚀 HƯỚNG DẪN TÍCH HỢP FRONTEND VỚI FINERACT

## 📋 PHÂN BIỆT QUAN TRỌNG

### **🔑 Keycloak vs Fineract Terminology**

| **Keycloak** | **Fineract** | **Mô tả** |
|--------------|--------------|-----------|
| **User** | **Client** | Người dùng cuối (khách hàng) |
| **Client** | **Application** | Ứng dụng frontend/mobile |
| **Realm** | **Tenant** | Môi trường làm việc |

### **⚠️ LƯU Ý QUAN TRỌNG**
- **Keycloak User** = **Fineract Client** (khách hàng)
- **Keycloak Client** = **Application** (ứng dụng của bạn)
- **Login** = Sử dụng **self-service API**, KHÔNG phải admin API

## 🔐 LUỒNG XÁC THỰC CHO FRONTEND

### **1. Self-Service Authentication (Cho khách hàng)**

#### **Endpoint Login**
```http
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

username={fineract_client_id}&password={client_password}&client_id=community-app&grant_type=password&client_secret=real-client-secret-123
```

#### **Data gửi đi:**
```javascript
const loginData = {
  username: "1",           // Fineract Client ID (không phải Keycloak User)
  password: "password",     // Password của Fineract Client
  client_id: "community-app",
  grant_type: "password",
  client_secret: "real-client-secret-123"
};
```

#### **Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6IC...",
  "expires_in": 3600,
  "refresh_expires_in": 1800,
  "token_type": "Bearer",
  "scope": "profile email"
}
```

### **2. Admin API Authentication (Cho quản trị viên)**

#### **Endpoint Login**
```http
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

username=mifos&password=password&client_id=community-app&grant_type=password&client_secret=real-client-secret-123
```

#### **Data gửi đi:**
```javascript
const adminLoginData = {
  username: "mifos",        // Keycloak User (admin)
  password: "password",     // Password của Keycloak User
  client_id: "community-app",
  grant_type: "password",
  client_secret: "real-client-secret-123"
};
```

## 🏦 LUỒNG ĐĂNG KÝ CHO KHÁCH HÀNG

### **Bước 1: Tạo Fineract Client (Admin API)**

#### **Endpoint:**
```http
POST http://localhost:8080/fineract-provider/api/v1/clients?tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

#### **Data gửi đi:**
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

#### **Response:**
```json
{
  "officeId": 1,
  "clientId": 1,
  "resourceId": 1
}
```

### **Bước 2: Activate Fineract Client (Admin API)**

#### **Endpoint:**
```http
POST http://localhost:8080/fineract-provider/api/v1/clients/{clientId}?command=activate&tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

#### **Data gửi đi:**
```json
{
  "activationDate": "2025-10-20",
  "locale": "en",
  "dateFormat": "yyyy-MM-dd"
}
```

#### **Response:**
```json
{
  "officeId": 1,
  "clientId": 1,
  "resourceId": 1,
  "changes": {
    "status": {
      "id": 300,
      "code": "clientStatusType.active",
      "value": "Active"
    }
  }
}
```

### **Bước 3: Tạo Savings Account (Admin API)**

#### **Endpoint:**
```http
POST http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

#### **Data gửi đi:**
```json
{
  "submittedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "productId": 1,
  "clientId": 1,
  "locale": "en"
}
```

#### **Response:**
```json
{
  "officeId": 1,
  "clientId": 1,
  "savingsId": 2,
  "resourceId": 2,
  "gsimId": 0
}
```

### **Bước 4: Activate Savings Account (Admin API)**

#### **Endpoint:**
```http
POST http://localhost:8080/fineract-provider/api/v1/savingsaccounts/{savingsId}?command=activate&tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

#### **Data gửi đi:**
```json
{
  "activatedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en"
}
```

## 🔑 LUỒNG ĐĂNG NHẬP CHO KHÁCH HÀNG

### **Self-Service Login (Khách hàng sử dụng)**

#### **JavaScript Code:**
```javascript
class FineractAuthService {
  constructor() {
    this.keycloakUrl = "http://localhost:9000";
    this.fineractUrl = "http://localhost:8080/fineract-provider/api/v1";
    this.clientId = "community-app";
    this.clientSecret = "real-client-secret-123";
  }

  // Login với Fineract Client ID
  async loginWithClientId(clientId, password) {
    try {
      const response = await fetch(`${this.keycloakUrl}/realms/fineract/protocol/openid-connect/token`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          username: clientId.toString(),  // Fineract Client ID
          password: password,
          client_id: this.clientId,
          grant_type: 'password',
          client_secret: this.clientSecret
        })
      });

      if (!response.ok) {
        throw new Error(`Login failed: ${response.status}`);
      }

      const tokenData = await response.json();
      return tokenData;
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  }

  // Lấy thông tin tài khoản của khách hàng
  async getClientAccounts(accessToken) {
    try {
      const response = await fetch(`${this.fineractUrl}/savingsaccounts?tenantIdentifier=default`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Fineract-Platform-TenantId': 'default',
          'Accept': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`Failed to get accounts: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Get accounts error:', error);
      throw error;
    }
  }

  // Chuyển tiền vào tài khoản
  async depositToAccount(accessToken, accountId, amount, note) {
    try {
      const depositData = {
        transactionDate: new Date().toISOString().split('T')[0],
        transactionAmount: amount.toString(),
        paymentTypeId: 1,
        note: note,
        dateFormat: "yyyy-MM-dd",
        locale: "en"
      };

      const response = await fetch(`${this.fineractUrl}/savingsaccounts/${accountId}/transactions?command=deposit&tenantIdentifier=default`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
          'Fineract-Platform-TenantId': 'default',
          'Accept': 'application/json'
        },
        body: JSON.stringify(depositData)
      });

      if (!response.ok) {
        throw new Error(`Deposit failed: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      console.error('Deposit error:', error);
      throw error;
    }
  }
}
```

### **React Native Component Example:**

```javascript
import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert } from 'react-native';

const LoginScreen = () => {
  const [clientId, setClientId] = useState('');
  const [password, setPassword] = useState('');
  const [authService] = useState(new FineractAuthService());
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = async () => {
    if (!clientId || !password) {
      Alert.alert('Error', 'Please enter client ID and password');
      return;
    }

    setIsLoading(true);
    try {
      // Login với Fineract Client ID
      const tokenData = await authService.loginWithClientId(clientId, password);
      
      // Lưu token vào storage
      await AsyncStorage.setItem('access_token', tokenData.access_token);
      await AsyncStorage.setItem('client_id', clientId);
      
      // Chuyển đến màn hình chính
      navigation.navigate('Dashboard');
      
    } catch (error) {
      Alert.alert('Login Failed', error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Fineract Login</Text>
      
      <TextInput
        style={styles.input}
        placeholder="Client ID (Fineract Client ID)"
        value={clientId}
        onChangeText={setClientId}
        keyboardType="numeric"
      />
      
      <TextInput
        style={styles.input}
        placeholder="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />
      
      <TouchableOpacity 
        style={styles.button} 
        onPress={handleLogin}
        disabled={isLoading}
      >
        <Text style={styles.buttonText}>
          {isLoading ? 'Logging in...' : 'Login'}
        </Text>
      </TouchableOpacity>
    </View>
  );
};
```

## 📱 LUỒNG HOÀN CHỈNH CHO FRONTEND

### **1. Đăng ký khách hàng mới (Admin thực hiện)**

```javascript
// Admin tạo client mới
const createNewClient = async (adminToken, clientData) => {
  const response = await fetch('http://localhost:8080/fineract-provider/api/v1/clients?tenantIdentifier=default', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json',
      'Fineract-Platform-TenantId': 'default'
    },
    body: JSON.stringify(clientData)
  });
  
  const result = await response.json();
  return result.clientId; // Trả về Client ID để khách hàng đăng nhập
};
```

### **2. Khách hàng đăng nhập (Self-service)**

```javascript
// Khách hàng đăng nhập bằng Client ID
const customerLogin = async (clientId, password) => {
  const response = await fetch('http://localhost:9000/realms/fineract/protocol/openid-connect/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      username: clientId.toString(),
      password: password,
      client_id: 'community-app',
      grant_type: 'password',
      client_secret: 'real-client-secret-123'
    })
  });
  
  return await response.json();
};
```

### **3. Khách hàng xem tài khoản**

```javascript
// Khách hàng xem danh sách tài khoản
const getCustomerAccounts = async (accessToken) => {
  const response = await fetch('http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default', {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Fineract-Platform-TenantId': 'default',
      'Accept': 'application/json'
    }
  });
  
  return await response.json();
};
```

## 🔧 API ENDPOINTS CHO FRONTEND

### **Authentication Endpoints**

| **Endpoint** | **Method** | **Mô tả** | **Sử dụng** |
|--------------|------------|-----------|-------------|
| `/realms/fineract/protocol/openid-connect/token` | POST | Lấy access token | Login khách hàng |
| `/realms/fineract/protocol/openid-connect/userinfo` | GET | Lấy thông tin user | Verify token |

### **Fineract Self-Service Endpoints**

| **Endpoint** | **Method** | **Mô tả** | **Sử dụng** |
|--------------|------------|-----------|-------------|
| `/api/v1/savingsaccounts` | GET | Lấy danh sách tài khoản | Khách hàng xem tài khoản |
| `/api/v1/savingsaccounts/{id}` | GET | Chi tiết tài khoản | Khách hàng xem chi tiết |
| `/api/v1/savingsaccounts/{id}/transactions` | GET | Lịch sử giao dịch | Khách hàng xem lịch sử |
| `/api/v1/savingsaccounts/{id}/transactions?command=deposit` | POST | Nạp tiền | Khách hàng nạp tiền |
| `/api/v1/savingsaccounts/{id}/transactions?command=withdrawal` | POST | Rút tiền | Khách hàng rút tiền |

### **Fineract Admin Endpoints (Chỉ admin sử dụng)**

| **Endpoint** | **Method** | **Mô tả** | **Sử dụng** |
|--------------|------------|-----------|-------------|
| `/api/v1/clients` | POST | Tạo client mới | Admin tạo khách hàng |
| `/api/v1/clients/{id}?command=activate` | POST | Activate client | Admin kích hoạt khách hàng |
| `/api/v1/savingsaccounts` | POST | Tạo savings account | Admin tạo tài khoản |
| `/api/v1/savingsaccounts/{id}?command=approve` | POST | Approve account | Admin duyệt tài khoản |
| `/api/v1/savingsaccounts/{id}?command=activate` | POST | Activate account | Admin kích hoạt tài khoản |

## 🚨 LƯU Ý QUAN TRỌNG CHO FRONTEND

### **1. Phân biệt rõ ràng:**
- **Admin API**: Chỉ dùng để tạo client, tạo account (backend/admin thực hiện)
- **Self-Service API**: Khách hàng đăng nhập và sử dụng

### **2. Authentication Flow:**
- **Khách hàng đăng nhập**: Sử dụng `clientId` (Fineract Client ID) làm username
- **Admin đăng nhập**: Sử dụng `mifos` (Keycloak User) làm username

### **3. Token Management:**
- Lưu `access_token` vào AsyncStorage
- Refresh token khi hết hạn
- Xử lý lỗi 401 Unauthorized

### **4. Error Handling:**
```javascript
const handleApiError = (error) => {
  if (error.status === 401) {
    // Token hết hạn, redirect to login
    navigation.navigate('Login');
  } else if (error.status === 403) {
    // Không có quyền
    Alert.alert('Error', 'You do not have permission to perform this action');
  } else {
    // Lỗi khác
    Alert.alert('Error', error.message);
  }
};
```

## 📊 TESTING VỚI POSTMAN

### **1. Test Self-Service Login:**
```http
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

username=1&password=password&client_id=community-app&grant_type=password&client_secret=real-client-secret-123
```

### **2. Test Get Accounts:**
```http
GET http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default
Authorization: Bearer {access_token}
Fineract-Platform-TenantId: default
```

### **3. Test Deposit:**
```http
POST http://localhost:8080/fineract-provider/api/v1/savingsaccounts/1/transactions?command=deposit&tenantIdentifier=default
Authorization: Bearer {access_token}
Content-Type: application/json
Fineract-Platform-TenantId: default

{
  "transactionDate": "2025-10-20",
  "transactionAmount": "1000000",
  "paymentTypeId": 1,
  "note": "Test deposit",
  "dateFormat": "yyyy-MM-dd",
  "locale": "en"
}
```

---

**Tóm tắt**: Khách hàng đăng nhập bằng **Fineract Client ID**, không phải Keycloak User. Admin sử dụng admin API để tạo client, khách hàng sử dụng self-service API để đăng nhập và quản lý tài khoản.
