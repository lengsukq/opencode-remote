# Generates an Android signing keystore for release builds
# Output: config/keystore/release.keystore
# Also creates config/keystore/key.properties for Gradle signing config

$keystorePath = Join-Path $PSScriptRoot "keystore"
$keystoreFile = Join-Path $keystorePath "release.keystore"
$propsFile = Join-Path $keystorePath "key.properties"

if (Test-Path $keystoreFile) {
  Write-Host "Keystore already exists: $keystoreFile"
  Write-Host "To regenerate, delete it first: Remove-Item '$keystoreFile'"
  exit 0
}

$storePass = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
$keyPass = $storePass
$keyAlias = "opencode-remote"
$dname = "CN=OpenCode Remote, OU=Development, O=opencode, L=Unknown, ST=Unknown, C=CN"

Write-Host "Generating keystore at: $keystoreFile"
Write-Host ""

& keytool -genkey -v `
  -keystore "$keystoreFile" `
  -alias "$keyAlias" `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -storepass "$storePass" `
  -keypass "$keyPass" `
  -dname "$dname" `
  -noprompt

if ($LASTEXITCODE -ne 0) {
  Write-Error "keytool failed. Make sure JDK is installed and in PATH."
  exit 1
}

"storePassword=$storePass" | Out-File -FilePath $propsFile -Encoding ascii
"keyPassword=$keyPass" | Out-File -FilePath $propsFile -Encoding ascii -Append
"keyAlias=$keyAlias" | Out-File -FilePath $propsFile -Encoding ascii -Append
"storeFile=../config/keystore/release.keystore" | Out-File -FilePath $propsFile -Encoding ascii -Append

Write-Host ""
Write-Host "Keystore generated successfully!"
Write-Host "  File: $keystoreFile"
Write-Host "  Props: $propsFile"
Write-Host ""
Write-Host "IMPORTANT: Keep storePassword and keyPassword secure."
Write-Host "The config/keystore/ directory is gitignored."
