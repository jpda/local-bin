# local-bin

tools & scripts

## adfsrp.sh
Coming soon

## ascend
Submits PIM elevation request. If self-activate eligible, will self-activate. Update `principalId` to the targeted principal.

## bingpic
Downloads the latest Bing picture of the day and sets as wallpaper.

## base-font.css
Safari overrides for Segoe UI font-family, as Safari will not use user-installed fonts with tracking protection enabled. This switches Segoe to --apple-system font, improving sites that lack fall-back fonts.

## dev-jwts
Apple arm64 build of [@DamianEdwards](https://github.com/DamianEdwards)' [jwt generator](https://github.com/DamianEdwards/AspNetCoreDevJwts)

## domains & domains.ps1
Finds domains associated with AAD tenants. Accepts a domain or tenant ID

## gateway
Gets a token for the Arcadyan KVD21 T-Mobile Home Internet gateway, to use in later scripts. Expects the gateway's admin password in the `$GATEWAY_ADMIN_PASSWORD` environment variable.

## keylights.ps1
Controls Elgato Key Lights. Requires IP address of Key Light; including `-On` switch will turn on lights, otherwise will turn off.

## mgc (Microsoft Graph CLI)
Apple arm64 build of the preview [Microsoft Graph CLI](https://github.com/microsoftgraph/msgraph-cli).

## power
(Poorly) scrapes `apcupsd` status page and returns wattage, derived from `NOMPOWER` and `LOADPCT` values. 

## teamsup
Updates `Microsoft Teams.app` on Apple Silicon machines without Rosetta.

## config/DefaultKeyBinding.dict
Updating default key bindings to make `Home` and `End` work per-line as expected.