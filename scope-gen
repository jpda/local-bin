#!/bin/bash
# generates json required to add delegated oauth2 scopes to AAD apps
# todo: app id pipe or arg $1
# outputs: json to PATCH app with

app_id=556214c6-dc59-42bc-af78-48c3abd37a54
app=$(az ad app show --id $app_id)
oldScopes=$(echo $app | jq .api.oauth2PermissionScopes)
newScopes=$(echo "{
    \"id\":\"$(uuidgen)\",
    \"adminConsentDescription\": \"number2\",
    \"adminConsentDisplayName\": \"number2\",
    \"isEnabled\": true,
    \"type\": \"Admin\",
    \"userConsentDescription\": \"number2\",
    \"userConsentDisplayName\": \"number2\",
    \"value\": \"number2\", 
}");

newScopeBlock=$(echo $oldScopes | jq ". + [${newScopes}]")
api=$(echo $app | jq .api)
newApiBlock=$(echo $api | jq ". | { acceptMappedClaims,knownClientApplications,preAuthorizedApplications,requestedAccessTokenVersion,oauth2PermissionScopes: ${newScopeBlock}}")
echo $newApiBlock

# PATCH /applications/app-id
# az ad app update --id 556214c6-dc59-42bc-af78-48c3abd37a54 --set "api=${newApiBlock}" --verbose