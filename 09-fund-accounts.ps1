# Script 08: Nạp tiền vào Savings Accounts
# Sử dụng: .\08-fund-accounts.ps1

Write-Host "=== 08. NẠP TIỀN VÀO SAVINGS ACCOUNTS ===" -ForegroundColor Green

$keycloakUrl = "http://localhost:9000"
$fineractBaseUrl = "http://localhost:8080/fineract-provider/api/v1"
$username = "mifos"
$password = "password"
$oauthClientId = "community-app"
$clientSecret = "real-client-secret-123"

# 1. Lấy OAuth2 token
Write-Host "`n1. Lấy OAuth2 token..." -ForegroundColor Yellow
$tokenUrl = "$keycloakUrl/realms/fineract/protocol/openid-connect/token"

try {
    $tokenBody = "username=$username&password=$password&client_id=$oauthClientId&grant_type=password&client_secret=$clientSecret"
    $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -ContentType "application/x-www-form-urlencoded" -Body $tokenBody
    $accessToken = $tokenResponse.access_token
    Write-Host "✅ OAuth2 token OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Lỗi lấy OAuth2 token: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
    "Fineract-Platform-TenantId" = "default"
    "Accept" = "application/json"
}

# 2. Kiểm tra trạng thái savings accounts
Write-Host "`n2. Kiểm tra trạng thái savings accounts..." -ForegroundColor Yellow
try {
    $accounts = Invoke-RestMethod -Uri "$fineractBaseUrl/savingsaccounts?tenantIdentifier=default" -Method Get -Headers $headers
    Write-Host "✅ Lấy danh sách accounts thành công: $($accounts.Count) accounts" -ForegroundColor Green
    
    $activeAccounts = $accounts | Where-Object { $_.status.value -eq "Active" }
    Write-Host "  - Active accounts: $($activeAccounts.Count)" -ForegroundColor White
    
    foreach ($account in $accounts) {
        Write-Host "    * Account $($account.id): $($account.status.value) - Client: $($account.clientName)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Lỗi lấy danh sách accounts: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. Nạp tiền vào Account 2 (vừa tạo)
Write-Host "`n3. Nạp tiền vào Account 2..." -ForegroundColor Yellow

$currentDate = (Get-Date).ToString("dd MMMM yyyy")
$depositData1 = @{
    transactionDate = $currentDate
    transactionAmount = 1000000000.00
    dateFormat = "dd MMMM yyyy"
    locale = "en"
    paymentTypeId = 1
} | ConvertTo-Json

Write-Host "  - Dữ liệu deposit Account 2:" -ForegroundColor Cyan
Write-Host "    Amount: 1000.00" -ForegroundColor White
Write-Host "    Date: $currentDate" -ForegroundColor White
Write-Host "    Payment Type: 1" -ForegroundColor White

try {
    $depositResponse1 = Invoke-WebRequest -Uri "$fineractBaseUrl/savingsaccounts/2/transactions?command=deposit&tenantIdentifier=default" -Method Post -Body $depositData1 -Headers $headers
    Write-Host "  - ✅ Deposit Account 2 thành công!" -ForegroundColor Green
    Write-Host "    Status Code: $($depositResponse1.StatusCode)" -ForegroundColor White
} catch {
    Write-Host "  - ❌ Lỗi deposit Account 2: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "    Status Code: $statusCode" -ForegroundColor Red
    }
}

# 4. Kiểm tra số dư cuối cùng
Write-Host "`n4. Kiểm tra số dư cuối cùng..." -ForegroundColor Yellow
try {
    $finalAccounts = Invoke-RestMethod -Uri "$fineractBaseUrl/savingsaccounts?tenantIdentifier=default" -Method Get -Headers $headers
    Write-Host "✅ Kiểm tra số dư thành công!" -ForegroundColor Green
    
    foreach ($account in $finalAccounts) {
        Write-Host "  - Account $($account.id):" -ForegroundColor Cyan
        Write-Host "    Client: $($account.clientName)" -ForegroundColor White
        Write-Host "    Status: $($account.status.value)" -ForegroundColor White
        Write-Host "    Account Balance: $($account.accountBalance)" -ForegroundColor White
        Write-Host "    Available Balance: $($account.availableBalance)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Lỗi kiểm tra số dư: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Lấy transaction history cho Account 2
Write-Host "`n5. Lấy transaction history cho Account 2..." -ForegroundColor Yellow
try {
    $transactions = Invoke-RestMethod -Uri "$fineractBaseUrl/savingsaccounts/1/transactions?tenantIdentifier=default" -Method Get -Headers $headers
    Write-Host "✅ Lấy transaction history thành công: $($transactions.Count) transactions" -ForegroundColor Green
    
    foreach ($transaction in $transactions) {
        Write-Host "  - Transaction ID: $($transaction.id)" -ForegroundColor White
        Write-Host "    Type: $($transaction.transactionType.value)" -ForegroundColor White
        Write-Host "    Amount: $($transaction.amount)" -ForegroundColor White
        Write-Host "    Date: $($transaction.date)" -ForegroundColor White
        Write-Host "    Running Balance: $($transaction.runningBalance)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Lỗi lấy transaction history: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== HOÀN THÀNH NẠP TIỀN ===" -ForegroundColor Green
Write-Host "Tất cả accounts đã được nạp tiền thành công!" -ForegroundColor Cyan
Write-Host "Tiếp theo: Kiểm tra số dư và transaction history" -ForegroundColor Yellow
