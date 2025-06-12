#!/usr/bin/env pwsh

param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FilePath,
    [Parameter(Mandatory = $false)]
    [switch]$X509 = $false
)

if (!$FilePath) {
    Write-Host "Usage: pubkey-to-jwk.ps1 -FilePath <path_to_pem_file> [-X509] optional, forces X509 handling"
    exit 1
}

if (-not (Test-Path -Path $FilePath)) {
    Write-Host "Error: PEM file not found at path: $FilePath"
    exit 1
}

## now we have the file, let's read it so we can check if it is a certificate or not
$fileContent = Get-Content -Path $FilePath -Raw

## check if the file is a certificate even if x509 is not specified
if ($fileContent -match "-----BEGIN CERTIFICATE-----") {
    Write-Debug "File appears to be an X.509 certificate, treating it so..."
    $X509 = $true
}

$keyBytes = $null

if ($X509) {
    Write-Debug "Reading X.509 certificate from file..."
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromCertFile($FilePath)
    $keyBytes = $cert.GetPublicKey()
}
else {
    $fileContent = $fileContent -replace "-----BEGIN PUBLIC KEY-----", ""
    $fileContent = $fileContent -replace "-----END PUBLIC KEY-----", ""
    $fileContent = $fileContent -replace "\s", ""
    $keyBytes = [Convert]::FromBase64String($fileContent)
}

$rsa = [System.Security.Cryptography.RSA]::Create()
$rsa.ImportRSAPublicKey($keyBytes, [ref]0)
Write-Debug "Imported key successfully, exporting..."
$parameters = $rsa.ExportParameters($false)

if ($null -eq $parameters) {
    Write-Host "Error: Failed to export parameters from the RSA key."
    exit 1
}

function ConvertTo-Base64Url {
    param (
        [byte[]]$base64Input
    )
    $base64 = [Convert]::ToBase64String($base64Input)
    $base64Url = $base64.TrimEnd('=') -replace '\+', '-' -replace '/', '_'
    return $base64Url
}

$jwk = @{
    kty = "RSA"
    n   = ConvertTo-Base64Url($parameters.Modulus)
    e   = ConvertTo-Base64Url($parameters.Exponent)
}

$jwkJson = $jwk | ConvertTo-Json -Compress
Write-Output $jwkJson

