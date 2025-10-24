# 🚀 HƯỚNG DẪN FRONTEND: TỪ TOKEN ĐẾN API CALL

## 📋 TỔNG QUAN LUỒNG

### **Luồng hoàn chỉnh:**
```
1. Lấy OAuth2 Token → 2. Lưu Token → 3. Call API với Token → 4. Xử lý Response → 5. Refresh Token
```

### **Phân biệt quan trọng:**
- **Admin Token**: Dùng để tạo client, activate client, tạo account
- **Customer Token**: Dùng để xem tài khoản, thực hiện giao dịch

## 🔑 BƯỚC 1: LẤY OAUTH2 TOKEN

### **1.1 Admin Login (Tạo client, quản lý hệ thống)**

#### **API Endpoint:**
```http
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded
```

#### **Data gửi đi:**
```
username=mifos&password=password&client_id=community-app&grant_type=password&client_secret=real-client-secret-123
```

#### **JavaScript Code:**
```javascript
class AdminAuthService {
  constructor() {
    this.keycloakUrl = "http://localhost:9000";
    this.clientId = "community-app";
    this.clientSecret = "real-client-secret-123";
  }

  async getAdminToken() {
    try {
      const response = await fetch(`${this.keycloakUrl}/realms/fineract/protocol/openid-connect/token`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          username: 'mifos',           // Keycloak User (admin)
          password: 'password',
          client_id: this.clientId,
          grant_type: 'password',
          client_secret: this.clientSecret
        })
      });

      if (!response.ok) {
        throw new Error(`Admin login failed: ${response.status}`);
      }

      const tokenData = await response.json();
      return tokenData;
    } catch (error) {
      console.error('Admin login error:', error);
      throw error;
    }
  }
}

// Sử dụng
const adminAuth = new AdminAuthService();
const adminTokenData = await adminAuth.getAdminToken();
console.log('Admin token:', adminTokenData.access_token);
```

### **1.2 Customer Login (Khách hàng đăng nhập)**

#### **API Endpoint:**
```http
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded
```

#### **Data gửi đi:**
```
username={clientId}&password={password}&client_id=community-app&grant_type=password&client_secret=real-client-secret-123
```

#### **JavaScript Code:**
```javascript
class CustomerAuthService {
  constructor() {
    this.keycloakUrl = "http://localhost:9000";
    this.clientId = "community-app";
    this.clientSecret = "real-client-secret-123";
  }

  async getCustomerToken(clientId, password) {
    try {
      const response = await fetch(`${this.keycloakUrl}/realms/fineract/protocol/openid-connect/token`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          username: clientId.toString(), // Fineract Client ID
          password: password,
          client_id: this.clientId,
          grant_type: 'password',
          client_secret: this.clientSecret
        })
      });

      if (!response.ok) {
        throw new Error(`Customer login failed: ${response.status}`);
      }

      const tokenData = await response.json();
      return tokenData;
    } catch (error) {
      console.error('Customer login error:', error);
      throw error;
    }
  }
}

// Sử dụng
const customerAuth = new CustomerAuthService();
const customerTokenData = await customerAuth.getCustomerToken("1", "password");
console.log('Customer token:', customerTokenData.access_token);
```

## 💾 BƯỚC 2: LƯU TOKEN

### **2.1 Lưu Token vào AsyncStorage (React Native)**

```javascript
import AsyncStorage from '@react-native-async-storage/async-storage';

class TokenManager {
  static async saveToken(tokenData, userType = 'customer') {
    try {
      await AsyncStorage.setItem(`${userType}_access_token`, tokenData.access_token);
      await AsyncStorage.setItem(`${userType}_refresh_token`, tokenData.refresh_token);
      await AsyncStorage.setItem(`${userType}_token_expires`, tokenData.expires_in.toString());
      await AsyncStorage.setItem(`${userType}_token_type`, tokenData.token_type);
      
      console.log('Token saved successfully');
    } catch (error) {
      console.error('Error saving token:', error);
      throw error;
    }
  }

  static async getToken(userType = 'customer') {
    try {
      const accessToken = await AsyncStorage.getItem(`${userType}_access_token`);
      const tokenType = await AsyncStorage.getItem(`${userType}_token_type`);
      
      if (!accessToken) {
        throw new Error('No token found');
      }
      
      return {
        accessToken,
        tokenType: tokenType || 'Bearer'
      };
    } catch (error) {
      console.error('Error getting token:', error);
      throw error;
    }
  }

  static async clearToken(userType = 'customer') {
    try {
      await AsyncStorage.removeItem(`${userType}_access_token`);
      await AsyncStorage.removeItem(`${userType}_refresh_token`);
      await AsyncStorage.removeItem(`${userType}_token_expires`);
      await AsyncStorage.removeItem(`${userType}_token_type`);
      
      console.log('Token cleared successfully');
    } catch (error) {
      console.error('Error clearing token:', error);
      throw error;
    }
  }
}

// Sử dụng
await TokenManager.saveToken(adminTokenData, 'admin');
await TokenManager.saveToken(customerTokenData, 'customer');
```

### **2.2 Lưu Token vào localStorage (Web)**

```javascript
class WebTokenManager {
  static saveToken(tokenData, userType = 'customer') {
    try {
      localStorage.setItem(`${userType}_access_token`, tokenData.access_token);
      localStorage.setItem(`${userType}_refresh_token`, tokenData.refresh_token);
      localStorage.setItem(`${userType}_token_expires`, tokenData.expires_in.toString());
      localStorage.setItem(`${userType}_token_type`, tokenData.token_type);
      
      console.log('Token saved successfully');
    } catch (error) {
      console.error('Error saving token:', error);
      throw error;
    }
  }

  static getToken(userType = 'customer') {
    try {
      const accessToken = localStorage.getItem(`${userType}_access_token`);
      const tokenType = localStorage.getItem(`${userType}_token_type`);
      
      if (!accessToken) {
        throw new Error('No token found');
      }
      
      return {
        accessToken,
        tokenType: tokenType || 'Bearer'
      };
    } catch (error) {
      console.error('Error getting token:', error);
      throw error;
    }
  }

  static clearToken(userType = 'customer') {
    try {
      localStorage.removeItem(`${userType}_access_token`);
      localStorage.removeItem(`${userType}_refresh_token`);
      localStorage.removeItem(`${userType}_token_expires`);
      localStorage.removeItem(`${userType}_token_type`);
      
      console.log('Token cleared successfully');
    } catch (error) {
      console.error('Error clearing token:', error);
      throw error;
    }
  }
}
```

## 🏦 BƯỚC 3: CALL API VỚI TOKEN

### **3.1 Fineract API Service**

```javascript
class FineractAPIService {
  constructor() {
    this.baseUrl = "http://localhost:8080/fineract-provider/api/v1";
    this.tenantId = "default";
  }

  // Tạo headers với token
  async createHeaders(userType = 'customer') {
    const tokenData = await TokenManager.getToken(userType);
    
    return {
      'Authorization': `${tokenData.tokenType} ${tokenData.accessToken}`,
      'Content-Type': 'application/json',
      'Fineract-Platform-TenantId': this.tenantId,
      'Accept': 'application/json'
    };
  }

  // Generic API call method
  async callAPI(endpoint, method = 'GET', data = null, userType = 'customer') {
    try {
      const headers = await this.createHeaders(userType);
      const url = `${this.baseUrl}${endpoint}?tenantIdentifier=${this.tenantId}`;
      
      const config = {
        method,
        headers,
        ...(data && { body: JSON.stringify(data) })
      };

      const response = await fetch(url, config);
      
      if (!response.ok) {
        throw new Error(`API call failed: ${response.status} ${response.statusText}`);
      }

      return await response.json();
    } catch (error) {
      console.error('API call error:', error);
      throw error;
    }
  }
}
```

### **3.2 Admin API Calls**

```javascript
class AdminAPIService extends FineractAPIService {
  // Tạo client mới
  async createClient(clientData) {
    return await this.callAPI('/clients', 'POST', clientData, 'admin');
  }

  // Activate client
  async activateClient(clientId) {
    const activateData = {
      activationDate: new Date().toISOString().split('T')[0],
      locale: "en",
      dateFormat: "yyyy-MM-dd"
    };
    
    return await this.callAPI(`/clients/${clientId}?command=activate`, 'POST', activateData, 'admin');
  }

  // Tạo savings account
  async createSavingsAccount(clientId, productId) {
    const accountData = {
      submittedOnDate: new Date().toLocaleDateString('en-GB', {
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      }),
      dateFormat: "dd MMMM yyyy",
      productId: productId,
      clientId: clientId,
      locale: "en"
    };
    
    return await this.callAPI('/savingsaccounts', 'POST', accountData, 'admin');
  }

  // Activate savings account
  async activateSavingsAccount(savingsId) {
    const activateData = {
      activatedOnDate: new Date().toLocaleDateString('en-GB', {
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      }),
      dateFormat: "dd MMMM yyyy",
      locale: "en"
    };
    
    return await this.callAPI(`/savingsaccounts/${savingsId}?command=activate`, 'POST', activateData, 'admin');
  }
}
```

### **3.3 Customer API Calls**

```javascript
class CustomerAPIService extends FineractAPIService {
  // Lấy danh sách tài khoản
  async getAccounts() {
    return await this.callAPI('/savingsaccounts', 'GET', null, 'customer');
  }

  // Lấy chi tiết tài khoản
  async getAccountDetails(accountId) {
    return await this.callAPI(`/savingsaccounts/${accountId}`, 'GET', null, 'customer');
  }

  // Lấy lịch sử giao dịch
  async getTransactionHistory(accountId) {
    return await this.callAPI(`/savingsaccounts/${accountId}/transactions`, 'GET', null, 'customer');
  }

  // Nạp tiền
  async deposit(accountId, amount, note) {
    const depositData = {
      transactionDate: new Date().toISOString().split('T')[0],
      transactionAmount: amount.toString(),
      paymentTypeId: 1,
      note: note,
      dateFormat: "yyyy-MM-dd",
      locale: "en"
    };
    
    return await this.callAPI(`/savingsaccounts/${accountId}/transactions?command=deposit`, 'POST', depositData, 'customer');
  }

  // Rút tiền
  async withdraw(accountId, amount, note) {
    const withdrawData = {
      transactionDate: new Date().toISOString().split('T')[0],
      transactionAmount: amount.toString(),
      paymentTypeId: 1,
      note: note,
      dateFormat: "yyyy-MM-dd",
      locale: "en"
    };
    
    return await this.callAPI(`/savingsaccounts/${accountId}/transactions?command=withdrawal`, 'POST', withdrawData, 'customer');
  }
}
```

## 📱 BƯỚC 4: REACT NATIVE COMPONENTS

### **4.1 Admin Registration Component**

```javascript
import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert, ScrollView } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const AdminRegistrationScreen = () => {
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
      // 1. Lấy admin token
      const adminAuth = new AdminAuthService();
      const adminTokenData = await adminAuth.getAdminToken();
      await TokenManager.saveToken(adminTokenData, 'admin');
      
      // 2. Tạo client
      const adminAPI = new AdminAPIService();
      const clientResult = await adminAPI.createClient({
        officeId: 1,
        legalFormId: 1,
        firstname: formData.firstname,
        lastname: formData.lastname,
        dateOfBirth: formData.dateOfBirth,
        locale: "en",
        dateFormat: "yyyy-MM-dd",
        active: false
      });
      
      // 3. Activate client
      await adminAPI.activateClient(clientResult.clientId);
      
      // 4. Tạo savings account
      const accountResult = await adminAPI.createSavingsAccount(clientResult.clientId, 1);
      
      // 5. Activate savings account
      await adminAPI.activateSavingsAccount(accountResult.savingsId);
      
      Alert.alert('Success', `Customer registered successfully!\nClient ID: ${clientResult.clientId}\nPassword: ${formData.password}`);
      
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

### **4.2 Customer Login Component**

```javascript
import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert } from 'react-native';

const CustomerLoginScreen = () => {
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
      // 1. Lấy customer token
      const customerAuth = new CustomerAuthService();
      const customerTokenData = await customerAuth.getCustomerToken(clientId, password);
      
      // 2. Lưu token
      await TokenManager.saveToken(customerTokenData, 'customer');
      
      // 3. Chuyển đến màn hình chính
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

### **4.3 Customer Dashboard Component**

```javascript
import React, { useState, useEffect } from 'react';
import { View, Text, FlatList, TouchableOpacity, Alert, RefreshControl } from 'react-native';

const CustomerDashboard = () => {
  const [accounts, setAccounts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadAccounts = async () => {
    try {
      const customerAPI = new CustomerAPIService();
      const accountsData = await customerAPI.getAccounts();
      setAccounts(accountsData.pageItems || []);
    } catch (error) {
      Alert.alert('Error', 'Failed to load accounts');
      console.error('Load accounts error:', error);
    } finally {
      setIsLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadAccounts();
  }, []);

  const onRefresh = () => {
    setRefreshing(true);
    loadAccounts();
  };

  const handleDeposit = async (accountId) => {
    try {
      const amount = prompt('Enter amount to deposit:');
      if (!amount || isNaN(amount)) {
        Alert.alert('Error', 'Please enter a valid amount');
        return;
      }

      const customerAPI = new CustomerAPIService();
      await customerAPI.deposit(accountId, amount, 'Mobile deposit');
      
      Alert.alert('Success', 'Deposit successful');
      loadAccounts(); // Reload accounts
    } catch (error) {
      Alert.alert('Error', 'Deposit failed');
    }
  };

  const renderAccount = ({ item }) => (
    <View style={styles.accountCard}>
      <Text style={styles.accountId}>Account ID: {item.id}</Text>
      <Text style={styles.accountBalance}>Balance: {item.accountBalance} {item.currency?.code}</Text>
      <Text style={styles.accountStatus}>Status: {item.status?.value}</Text>
      
      <TouchableOpacity 
        style={styles.depositButton}
        onPress={() => handleDeposit(item.id)}
      >
        <Text style={styles.buttonText}>Deposit</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      <Text style={styles.title}>My Accounts</Text>
      
      <FlatList
        data={accounts}
        renderItem={renderAccount}
        keyExtractor={(item) => item.id.toString()}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        ListEmptyComponent={
          <Text style={styles.emptyText}>No accounts found</Text>
        }
      />
    </View>
  );
};
```

## 🔄 BƯỚC 5: REFRESH TOKEN

### **5.1 Token Refresh Service**

```javascript
class TokenRefreshService {
  constructor() {
    this.keycloakUrl = "http://localhost:9000";
    this.clientId = "community-app";
    this.clientSecret = "real-client-secret-123";
  }

  async refreshToken(userType = 'customer') {
    try {
      const refreshToken = await AsyncStorage.getItem(`${userType}_refresh_token`);
      
      if (!refreshToken) {
        throw new Error('No refresh token found');
      }

      const response = await fetch(`${this.keycloakUrl}/realms/fineract/protocol/openid-connect/token`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          grant_type: 'refresh_token',
          refresh_token: refreshToken,
          client_id: this.clientId,
          client_secret: this.clientSecret
        })
      });

      if (!response.ok) {
        throw new Error(`Token refresh failed: ${response.status}`);
      }

      const tokenData = await response.json();
      await TokenManager.saveToken(tokenData, userType);
      
      return tokenData;
    } catch (error) {
      console.error('Token refresh error:', error);
      throw error;
    }
  }
}
```

### **5.2 Auto Token Refresh**

```javascript
class AutoRefreshService {
  constructor() {
    this.refreshService = new TokenRefreshService();
    this.refreshInterval = null;
  }

  startAutoRefresh(userType = 'customer') {
    // Refresh token every 50 minutes (tokens expire in 60 minutes)
    this.refreshInterval = setInterval(async () => {
      try {
        await this.refreshService.refreshToken(userType);
        console.log('Token refreshed automatically');
      } catch (error) {
        console.error('Auto refresh failed:', error);
        // Redirect to login
        navigation.navigate('Login');
      }
    }, 50 * 60 * 1000); // 50 minutes
  }

  stopAutoRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
      this.refreshInterval = null;
    }
  }
}

// Sử dụng
const autoRefresh = new AutoRefreshService();
autoRefresh.startAutoRefresh('customer');
```

## 🚨 ERROR HANDLING

### **6.1 API Error Handler**

```javascript
class APIErrorHandler {
  static handleError(error, navigation) {
    if (error.message.includes('401')) {
      // Token hết hạn
      Alert.alert('Session Expired', 'Please login again', [
        { text: 'OK', onPress: () => navigation.navigate('Login') }
      ]);
    } else if (error.message.includes('403')) {
      // Không có quyền
      Alert.alert('Access Denied', 'You do not have permission to perform this action');
    } else if (error.message.includes('400')) {
      // Dữ liệu không hợp lệ
      Alert.alert('Invalid Data', 'Please check your input and try again');
    } else if (error.message.includes('404')) {
      // Không tìm thấy resource
      Alert.alert('Not Found', 'The requested resource was not found');
    } else {
      // Lỗi khác
      Alert.alert('Error', error.message);
    }
  }
}
```

### **6.2 Retry Logic**

```javascript
class APIRetryService {
  static async callWithRetry(apiCall, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await apiCall();
      } catch (error) {
        if (i === maxRetries - 1) {
          throw error;
        }
        
        // Wait before retry
        await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
      }
    }
  }
}

// Sử dụng
const result = await APIRetryService.callWithRetry(async () => {
  return await customerAPI.getAccounts();
});
```

## 📊 TESTING VỚI POSTMAN

### **7.1 Test Admin Flow**

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
```

### **7.2 Test Customer Flow**

```http
# 1. Customer login
POST http://localhost:9000/realms/fineract/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded
username=1&password=password&client_id=community-app&grant_type=password&client_secret=real-client-secret-123

# 2. Get accounts
GET http://localhost:8080/fineract-provider/api/v1/savingsaccounts?tenantIdentifier=default
Authorization: Bearer {customer_token}
Fineract-Platform-TenantId: default

# 3. Deposit money
POST http://localhost:8080/fineract-provider/api/v1/savingsaccounts/1/transactions?command=deposit&tenantIdentifier=default
Authorization: Bearer {customer_token}
Content-Type: application/json
Fineract-Platform-TenantId: default
```

## 🎯 TÓM TẮT LUỒNG

### **1. Admin Flow:**
```
Admin Login → Get Admin Token → Save Token → Create Client → Activate Client → Create Account → Activate Account
```

### **2. Customer Flow:**
```
Customer Login → Get Customer Token → Save Token → Get Accounts → Perform Transactions
```

### **3. Key Points:**
- **Admin**: Sử dụng `mifos/password` để login
- **Customer**: Sử dụng `{clientId}/password` để login
- **Token Management**: Lưu và refresh token tự động
- **Error Handling**: Xử lý lỗi 401, 403, 400, 404
- **API Calls**: Sử dụng token trong headers

---

**Hướng dẫn Frontend từ token đến API call đã hoàn thành!** 🚀
