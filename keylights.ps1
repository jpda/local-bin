[CmdletBinding()]
param ([switch] $On)

if($On) {
  Set-ElgatoKeyLight -Hostname @("10.10.10.40", "10.10.10.41") -Temperature 3400 -Brightness 30 -On
} else {
  Set-ElgatoKeyLight -Hostname @("10.10.10.40", "10.10.10.41") -Temperature 3400 -Brightness 30
}
