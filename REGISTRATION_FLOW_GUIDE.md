# 📝 HƯỚNG DẪN LUỒNG ĐĂNG KÝ KHÁCH HÀNG

## 🎯 TỔNG QUAN LUỒNG ĐĂNG KÝ

### **Luồng hoàn chỉnh:**
```
1. Admin tạo Fineract Client → 2. Admin activate Client → 3. Admin tạo Savings Account → 4. Admin activate Account → 5. Khách hàng đăng nhập
```

### **Phân quyền:**
- **Admin**: Tạo client, activate client, tạo account, activate account
- **Khách hàng**: Đăng nhập, xem tài khoản, thực hiện giao dịch

## 🔐 BƯỚC 1: ADMIN TẠO FINERACT CLIENT

### **API Endpoint:**
```http
POST http://localhost:8080/fineract-provider/api/v1/clients?tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

### **Data gửi đi:**
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

### **Response:**
```json
{
  "officeId": 1,
  "clientId": 1,
  "resourceId": 1
}
```

### **JavaScript Code:**
```javascript
const createFineractClient = async (adminToken, clientData) => {
  try {
    const response = await fetch('http://localhost:8080/fineract-provider/api/v1/clients?tenantIdentifier=default', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json',
        'Fineract-Platform-TenantId': 'default'
      },
      body: JSON.stringify(clientData)
    });

    if (!response.ok) {
      throw new Error(`Failed to create client: ${response.status}`);
    }

    const result = await response.json();
    return result.clientId; // Trả về Client ID để khách hàng đăng nhập
  } catch (error) {
    console.error('Error creating client:', error);
    throw error;
  }
};

// Sử dụng
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

const clientId = await createFineractClient(adminToken, clientData);
console.log('Created client with ID:', clientId);
```

## ✅ BƯỚC 2: ADMIN ACTIVATE CLIENT

### **API Endpoint:**
```http
POST http://localhost:8080/fineract-provider/api/v1/clients/{clientId}?command=activate&tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

### **Data gửi đi:**
```json
{
  "activationDate": "2025-10-20",
  "locale": "en",
  "dateFormat": "yyyy-MM-dd"
}
```

### **Response:**
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

### **JavaScript Code:**
```javascript
const activateFineractClient = async (adminToken, clientId) => {
  try {
    const response = await fetch(`http://localhost:8080/fineract-provider/api/v1/clients/${clientId}?command=activate&tenantIdentifier=default`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json',
        'Fineract-Platform-TenantId': 'default'
      },
      body: JSON.stringify({
        activationDate: new Date().toISOString().split('T')[0],
        locale: "en",
        dateFormat: "yyyy-MM-dd"
      })
    });

    if (!response.ok) {
      throw new Error(`Failed to activate client: ${response.status}`);
    }

    const result = await response.json();
    return result;
  } catch (error) {
    console.error('Error activating client:', error);
    throw error;
  }
};

// Sử dụng
await activateFineractClient(adminToken, clientId);
console.log('Client activated successfully');
```

## 🏦 BƯỚC 3: ADMIN TẠO SAVINGS ACCOUNT

### **API Endpoint:**
```http
POST http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

### **Data gửi đi:**
```json
{
  "submittedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "productId": 1,
  "clientId": 1,
  "locale": "en"
}
```

### **Response:**
```json
{
  "officeId": 1,
  "clientId": 1,
  "savingsId": 2,
  "resourceId": 2,
  "gsimId": 0
}
```

### **JavaScript Code:**
```javascript
const createSavingsAccount = async (adminToken, clientId, productId) => {
  try {
    const response = await fetch('http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json',
        'Fineract-Platform-TenantId': 'default'
      },
      body: JSON.stringify({
        submittedOnDate: new Date().toLocaleDateString('en-GB', {
          day: 'numeric',
          month: 'long',
          year: 'numeric'
        }),
        dateFormat: "dd MMMM yyyy",
        productId: productId,
        clientId: clientId,
        locale: "en"
      })
    });

    if (!response.ok) {
      throw new Error(`Failed to create savings account: ${response.status}`);
    }

    const result = await response.json();
    return result.savingsId;
  } catch (error) {
    console.error('Error creating savings account:', error);
    throw error;
  }
};

// Sử dụng
const savingsId = await createSavingsAccount(adminToken, clientId, 1);
console.log('Created savings account with ID:', savingsId);
```

## ✅ BƯỚC 4: ADMIN ACTIVATE SAVINGS ACCOUNT

### **API Endpoint:**
```http
POST http://localhost:8080/fineract-provider/api/v1/savingsaccounts/{savingsId}?command=activate&tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

### **Data gửi đi:**
```json
{
  "activatedOnDate": "20 October 2025",
  "dateFormat": "dd MMMM yyyy",
  "locale": "en"
}
```

### **Response:**
```json
{
  "officeId": 1,
  "clientId": 1,
  "savingsId": 2,
  "resourceId": 2,
  "changes": {
    "status": {
      "id": 300,
      "code": "savingsAccountStatusType.active",
      "value": "Active"
    }
  }
}
```

### **JavaScript Code:**
```javascript
const activateSavingsAccount = async (adminToken, savingsId) => {
  try {
    const response = await fetch(`http://localhost:8080/fineract-provider/api/v1/savingsaccounts/${savingsId}?command=activate&tenantIdentifier=default`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json',
        'Fineract-Platform-TenantId': 'default'
      },
      body: JSON.stringify({
        activatedOnDate: new Date().toLocaleDateString('en-GB', {
          day: 'numeric',
          month: 'long',
          year: 'numeric'
        }),
        dateFormat: "dd MMMM yyyy",
        locale: "en"
      })
    });

    if (!response.ok) {
      throw new Error(`Failed to activate savings account: ${response.status}`);
    }

    const result = await response.json();
    return result;
  } catch (error) {
    console.error('Error activating savings account:', error);
    throw error;
  }
};

// Sử dụng
await activateSavingsAccount(adminToken, savingsId);
console.log('Savings account activated successfully');
```

## 🔑 BƯỚC 5: KHÁCH HÀNG ĐĂNG NHẬP

### **API Endpoint:**
```http
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded
```

### **Data gửi đi:**
```
username={clientId}&password={password}&client_id=community-app&grant_type=password&client_secret=real-client-secret-123
```

### **Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6IC...",
  "expires_in": 3600,
  "refresh_expires_in": 1800,
  "token_type": "Bearer",
  "scope": "profile email"
}
```

### **JavaScript Code:**
```javascript
const customerLogin = async (clientId, password) => {
  try {
    const response = await fetch('http://localhost:9000/realms/fineract/protocol/openid-connect/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        username: clientId.toString(), // Fineract Client ID
        password: password,
        client_id: 'community-app',
        grant_type: 'password',
        client_secret: 'real-client-secret-123'
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
};

// Sử dụng
const tokenData = await customerLogin(clientId, password);
console.log('Login successful, access token:', tokenData.access_token);
```

## 📱 REACT NATIVE COMPONENT HOÀN CHỈNH

### **RegistrationScreen.js (Admin sử dụng):**
```javascript
import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert, ScrollView } from 'react-native';

const RegistrationScreen = () => {
  const [formData, setFormData] = useState({
    firstname: '',
    lastname: '',
    dateOfBirth: '',
    password: ''
  });
  const [isLoading, setIsLoading] = useState(false);

  const handleRegistration = async () => {
    if (!formData.firstname || !formData.lastname || !formData.dateOfBirth || !formData.password) {
      Alert.alert('Error', 'Please fill in all fields');
      return;
    }

    setIsLoading(true);
    try {
      // 1. Admin login để lấy token
      const adminToken = await getAdminToken();
      
      // 2. Tạo Fineract Client
      const clientId = await createFineractClient(adminToken, {
        officeId: 1,
        legalFormId: 1,
        firstname: formData.firstname,
        lastname: formData.lastname,
        dateOfBirth: formData.dateOfBirth,
        locale: "en",
        dateFormat: "yyyy-MM-dd",
        active: false
      });
      
      // 3. Activate Client
      await activateFineractClient(adminToken, clientId);
      
      // 4. Tạo Savings Account
      const savingsId = await createSavingsAccount(adminToken, clientId, 1);
      
      // 5. Activate Savings Account
      await activateSavingsAccount(adminToken, savingsId);
      
      Alert.alert('Success', `Customer registered successfully!\nClient ID: ${clientId}\nPassword: ${formData.password}`);
      
    } catch (error) {
      Alert.alert('Registration Failed', error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Customer Registration</Text>
      
      <TextInput
        style={styles.input}
        placeholder="First Name"
        value={formData.firstname}
        onChangeText={(text) => setFormData({...formData, firstname: text})}
      />
      
      <TextInput
        style={styles.input}
        placeholder="Last Name"
        value={formData.lastname}
        onChangeText={(text) => setFormData({...formData, lastname: text})}
      />
      
      <TextInput
        style={styles.input}
        placeholder="Date of Birth (YYYY-MM-DD)"
        value={formData.dateOfBirth}
        onChangeText={(text) => setFormData({...formData, dateOfBirth: text})}
      />
      
      <TextInput
        style={styles.input}
        placeholder="Password"
        value={formData.password}
        onChangeText={(text) => setFormData({...formData, password: text})}
        secureTextEntry
      />
      
      <TouchableOpacity 
        style={styles.button} 
        onPress={handleRegistration}
        disabled={isLoading}
      >
        <Text style={styles.buttonText}>
          {isLoading ? 'Registering...' : 'Register Customer'}
        </Text>
      </TouchableOpacity>
    </ScrollView>
  );
};
```

### **LoginScreen.js (Khách hàng sử dụng):**
```javascript
import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert } from 'react-native';

const LoginScreen = () => {
  const [clientId, setClientId] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = async () => {
    if (!clientId || !password) {
      Alert.alert('Error', 'Please enter Client ID and password');
      return;
    }

    setIsLoading(true);
    try {
      // Khách hàng đăng nhập bằng Client ID
      const tokenData = await customerLogin(clientId, password);
      
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
      <Text style={styles.title}>Customer Login</Text>
      
      <TextInput
        style={styles.input}
        placeholder="Client ID"
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

## 🔧 WORKFLOW HOÀN CHỈNH

### **1. Admin Workflow:**
```javascript
// Admin đăng nhập
const adminToken = await getAdminToken();

// Tạo khách hàng mới
const clientId = await createFineractClient(adminToken, clientData);
await activateFineractClient(adminToken, clientId);

// Tạo tài khoản tiết kiệm
const savingsId = await createSavingsAccount(adminToken, clientId, productId);
await activateSavingsAccount(adminToken, savingsId);

// Thông báo cho khách hàng
console.log(`Customer registered! Client ID: ${clientId}, Password: ${password}`);
```

### **2. Customer Workflow:**
```javascript
// Khách hàng đăng nhập
const tokenData = await customerLogin(clientId, password);

// Xem tài khoản
const accounts = await getCustomerAccounts(tokenData.access_token);

// Thực hiện giao dịch
await depositToAccount(tokenData.access_token, accountId, amount, note);
```

## 📊 TESTING VỚI POSTMAN

### **1. Test Admin Registration:**
```http
# 1. Admin login
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded
username=mifos&password=password&client_id=community-app&grant_type=password&client_secret=real-client-secret-123

# 2. Create client
POST http://localhost:8080/fineract-provider/api/v1/clients?tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default

# 3. Activate client
POST http://localhost:8080/fineract-provider/api/v1/clients/1?command=activate&tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default

# 4. Create savings account
POST http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default

# 5. Activate savings account
POST http://localhost:8080/fineract-provider/api/v1/savingsaccounts/1?command=activate&tenantIdentifier=default
Authorization: Bearer {admin_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

### **2. Test Customer Login:**
```http
# Customer login
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded
username=1&password=password&client_id=community-app&grant_type=password&client_secret=real-client-secret-123

# Get accounts
GET http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default
Authorization: Bearer {customer_token}
Fineract-Platform-TenantId: default
```

## 🚨 LƯU Ý QUAN TRỌNG

### **1. Phân quyền rõ ràng:**
- **Admin**: Tạo client, activate client, tạo account, activate account
- **Customer**: Đăng nhập, xem tài khoản, thực hiện giao dịch

### **2. Authentication:**
- **Admin login**: Sử dụng `mifos/password` (Keycloak User)
- **Customer login**: Sử dụng `{clientId}/password` (Fineract Client ID)

### **3. Error Handling:**
```javascript
const handleApiError = (error) => {
  if (error.status === 401) {
    // Token hết hạn
    navigation.navigate('Login');
  } else if (error.status === 403) {
    // Không có quyền
    Alert.alert('Error', 'You do not have permission');
  } else if (error.status === 400) {
    // Dữ liệu không hợp lệ
    Alert.alert('Error', 'Invalid data provided');
  } else {
    // Lỗi khác
    Alert.alert('Error', error.message);
  }
};
```

---

**Tóm tắt**: Luồng đăng ký bao gồm 5 bước: Admin tạo client → activate client → tạo account → activate account → khách hàng đăng nhập. Admin sử dụng admin API, khách hàng sử dụng self-service API.
