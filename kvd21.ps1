$ErrorActionPreference = 'SilentlyContinue'
function token
{
	
$Pass = Read-Host "Enter Password For The Gateway"
$body = @"
{
"username": "admin",
"password": "$Pass"
}
"@
$login = Invoke-RestMethod -Method POST -Uri "http://192.168.12.1/TMI/v1/auth/login" -Body $body
$token = $login.auth.token
$global:header = @{Authorization="Bearer $token"}

}

function Show-Menu
{
    param (
        [string]$Title = 'My Menu'
    )
    Clear-Host
    Write-Host "Options for Gateway"
    
    Write-Host "1: Press '1' to Turn Off Wifi."
    Write-Host "2: Press '2' to Turn On Wifi."
    Write-Host "3: Press '3' to Reboot Gateway."
    Write-Host "4: Press '4' to Download Config to Verify Changes."
    Write-Host "Q: Press 'Q' to Quit."
}

 
function wifi-off
{

$response = Invoke-RestMethod -Uri "http://192.168.12.1/TMI/v1/network/configuration?get=ap" -headers $global:header -o .\config.txt
((Get-Content -path .\config.txt -Raw) -Replace '"isRadioEnabled": true','"isRadioEnabled": false') | Set-Content -Path .\config.txt
$response = Invoke-RestMethod -TimeoutSec 1 -Method POST -Uri "http://192.168.12.1/TMI/v1/network/configuration?set=ap" -headers $global:header -body (Get-Content .\config.txt) -ContentType "application/json"

}
 

 function wifi-on
 {

$response = Invoke-RestMethod -Uri "http://192.168.12.1/TMI/v1/network/configuration?get=ap" -headers $global:header -o .\config.txt
((Get-Content -path .\config.txt -Raw) -Replace '"isRadioEnabled": false','"isRadioEnabled": true') | Set-Content -Path .\config.txt
$response = Invoke-RestMethod -TimeoutSec 1 -Method POST -Uri "http://192.168.12.1/TMI/v1/network/configuration?set=ap" -headers $global:header -body (Get-Content .\config.txt) -ContentType "application/json"

}


function config
{

$response = Invoke-RestMethod -Uri "http://192.168.12.1/TMI/v1/network/configuration?get=ap" -headers $global:header -o .\config.txt

}

function reboot
{

$response = Invoke-RestMethod -TimeoutSec 1 -Method POST -Uri "http://192.168.12.1/TMI/v1/gateway/reset?set=reboot" -headers $global:header

}



function menu
{


Show-Menu -Title 'My Menu'
 $selection = Read-Host "Please make a selection"
 switch ($selection)
 {
     '1' {
          token
'Turning off Wifi'
          wifi-off
  'Returning to Menu'
           Start-Sleep -s 1
          menu
         
     } '2' {
          token
'Turning on Wifi'
          wifi-on
  'Returning to Menu'
 Start-Sleep -s 1
          menu
         
     } '3' {
          token
'Rebooting Gateway'
Start-Sleep -s 1

          reboot
          return
         
     } '4' {token
          'Downloading config'
          config
          'Returning to Menu'
          Start-Sleep -s 1
          menu  
           
                    
     } 'q' {
         return
     }
 }

 }

menu

$response



