#!/usr/local/bin/pwsh
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Identifier
)

$endpoints = @(
    @{ Endpoint = "https://login.microsoftonline.com"; AudienceReplacement = "accounts.accesscontrol.windows.net" }, 
    @{ Endpoint = "https://login.microsoftonline.us"; AudienceReplacement = "login.microsoftonline.us" }, 
    @{ Endpoint = "https://login.partner.microsoftonline.cn"; AudienceReplacement = "accounts.accesscontrol.chinacloudapi.cn" }
)

Write-Host "Getting domain info for $Identifier"
foreach ($e in $endpoints) {
    Write-Host === Endpoint: $e.Endpoint ===
    $d = Invoke-RestMethod -Uri "$($e.Endpoint)/$Identifier/metadata/json/1" -Method Get `
        -SkipHttpErrorCheck `
        -StatusCodeVariable statusCode `
        -ErrorAction SilentlyContinue

    if ($statusCode -gt 299) {
        Write-Host Error: $statusCode
        Write-Host $d
        continue;
    }

    write-host $d

    $d.allowedAudiences | ForEach-Object { 
        Write-Host $_.ToString().Replace("00000001-0000-0000-c000-000000000000/$($e.AudienceReplacement)@", "") 
    }
}
