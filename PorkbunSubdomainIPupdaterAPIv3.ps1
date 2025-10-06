# Porkbun Dynamic DNS Updater - API v3
# Requires PowerShell 5+ or Core
# Use Task Scheduler to run every 120 seconds

# === CONFIGURATION ===
$ApiKey = "YOUR_API_KEY"
$SecretApiKey = "YOUR_SECRET_API_KEY"
$Domain = "example.com"          # Root domain
$Subdomain = "home"              # Subdomain to update (e.g., home.example.com)
$TTL = 600                       # Optional TTL value

# === STEP 1: Get Current Public IP ===
try {
    $response = Invoke-RestMethod -Uri "https://api.ipify.org?format=json"
    $currentIP = $response.ip
    Write-Host "Current public IP: $currentIP"
} catch {
    Write-Error "Failed to get public IP."
    exit 1
}

# === STEP 2: Get Existing Record from Porkbun ===
$retrieveBody = @{
    apikey       = $ApiKey
    secretapikey = $SecretApiKey
} | ConvertTo-Json

$retrieveUrl = "https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/$Domain/A/$Subdomain"
$dnsRecord = Invoke-RestMethod -Uri $retrieveUrl -Method POST -Body $retrieveBody -ContentType "application/json"

if ($dnsRecord.status -ne "SUCCESS") {
    Write-Error "Failed to retrieve DNS record."
    exit 1
}

$oldIP = $dnsRecord.records[0].content
Write-Host "Existing DNS IP: $oldIP"

# === STEP 3: Compare and Update if Needed ===
if ($oldIP -eq $currentIP) {
    Write-Host "IP has not changed. No update needed."
    exit 0
}

$updateBody = @{
    apikey       = $ApiKey
    secretapikey = $SecretApiKey
    content      = $currentIP
    ttl          = "$TTL"
} | ConvertTo-Json

$updateUrl = "https://api.porkbun.com/api/json/v3/dns/editByNameType/$Domain/A/$Subdomain"
$updateResponse = Invoke-RestMethod -Uri $updateUrl -Method POST -Body $updateBody -ContentType "application/json"

if ($updateResponse.status -eq "SUCCESS") {
    Write-Host "✅ DNS record updated successfully to $currentIP"
} else {
    Write-Error "❌ DNS update failed. Response: $($updateResponse | ConvertTo-Json -Depth 5)"
}
