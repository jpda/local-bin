#!/bin/bash
set -euo pipefail

# UniFi Network API sequence:
# 1) Power-cycle two radio-related ports
# 2) Optionally wait
# 3) Power-cycle receiver port
#
# NOTE: POWER_CYCLE is documented by UniFi Network API v10.6.106.

ENV_FILE="${UNIFI_ENV_FILE:-$HOME/.local/etc/unifi_hq.env}"

# Required identifiers. Set these before running, or export in your env file.
SITE_ID=""
CONSOLE_ID=""

# Either provide CONSOLE_ID (cloud connector) or CONSOLE_IP (local console).
CONSOLE_IP=""

# Sequence targets in "deviceId:portIdx" form.
# Provide exactly two entries for the radio port power-cycle sequence.
POE_TARGET_1=""
POE_TARGET_2=""

# Provide one entry for the final power-cycle.
CYCLE_TARGET=""

# Optional structured defaults for this specific flow.
RADIO_SWITCH_ID=""
RADIO_HUB_PORTIDX=""
RADIO_DEVICE_PORTIDX=""
RECEIVER_SWITCH_ID=""
RECEIVER_PORTIDX=""
RECEIVER_CYCLE_DELAY=""

# Documented in UniFi Network API v10.
POWER_CYCLE_ACTION=""

SHOW_URL=0
DRY_RUN=0
LIST_SITES=0
LIST_DEVICES=0
LIST_PORTS_DEVICE_ID=""

usage() {
	cat <<'EOF'
Usage:
	unifi-port-poe-sequence.sh [options]

Discovery options:
	--list-sites                 List available sites (id, internalReference, name)
	--list-devices               List devices in UNIFI_SITE_ID / --site-id
	--list-ports <deviceId>      List ports for a device in UNIFI_SITE_ID / --site-id

Run sequence options:
	--site-id <uuid>             Override UNIFI_SITE_ID
	--console-id <id>            Override UNIFI_CONSOLE_ID (cloud connector)
	--console-ip <ip-or-host>    Override UNIFI_CONSOLE_IP (local console)
	--wait-seconds <n>           Delay after radio-port cycles
	--receiver-cycle-delay <n>   Delay before final receiver cycle
	--show-url                   Print API URL for each request
	--dry-run                    Do not execute POST actions; print what would run

General:
	--help                       Show this help

Defaults are read from:
	UNIFI_ENV_FILE or ~/.local/etc/unifi_hq.env
EOF
}

log() {
	printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

die() {
	log "ERROR: $*"
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

apply_env_defaults() {
	SITE_ID="${SITE_ID:-${UNIFI_SITE_ID:-}}"
	CONSOLE_ID="${CONSOLE_ID:-${UNIFI_CONSOLE_ID:-}}"
	CONSOLE_IP="${CONSOLE_IP:-${UNIFI_CONSOLE_IP:-}}"

	POE_TARGET_1="${POE_TARGET_1:-${UNIFI_POE_TARGET_1:-}}"
	POE_TARGET_2="${POE_TARGET_2:-${UNIFI_POE_TARGET_2:-}}"
	CYCLE_TARGET="${CYCLE_TARGET:-${UNIFI_CYCLE_TARGET:-}}"

	RADIO_SWITCH_ID="${RADIO_SWITCH_ID:-${UNIFI_RADIO_SWITCH_ID:-}}"
	RADIO_HUB_PORTIDX="${RADIO_HUB_PORTIDX:-${UNIFI_RADIO_HUB_PORTIDX:-}}"
	RADIO_DEVICE_PORTIDX="${RADIO_DEVICE_PORTIDX:-${UNIFI_RADIO_DEVICE_PORTIDX:-}}"
	RECEIVER_SWITCH_ID="${RECEIVER_SWITCH_ID:-${UNIFI_RECEIVER_SWITCH_ID:-}}"
	RECEIVER_PORTIDX="${RECEIVER_PORTIDX:-${UNIFI_RECEIVER_PORTIDX:-${UNIFI_RECIEVER_PORTIDX:-}}}"
	RECEIVER_CYCLE_DELAY="${RECEIVER_CYCLE_DELAY:-${UNIFI_RECEIVER_CYCLE_DELAY:-${UNIFI_RECIEVER_CYCLE_DELAY:-20}}}"

	POWER_CYCLE_ACTION="${POWER_CYCLE_ACTION:-${UNIFI_POWER_CYCLE_ACTION:-POWER_CYCLE}}"
}

parse_args() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--list-sites)
			LIST_SITES=1
			shift
			;;
		--list-devices)
			LIST_DEVICES=1
			shift
			;;
		--list-ports)
			[[ $# -ge 2 ]] || die "--list-ports requires a deviceId"
			LIST_PORTS_DEVICE_ID="$2"
			shift 2
			;;
		--site-id)
			[[ $# -ge 2 ]] || die "--site-id requires a value"
			SITE_ID="$2"
			shift 2
			;;
		--console-id)
			[[ $# -ge 2 ]] || die "--console-id requires a value"
			CONSOLE_ID="$2"
			shift 2
			;;
		--console-ip)
			[[ $# -ge 2 ]] || die "--console-ip requires a value"
			CONSOLE_IP="$2"
			shift 2
			;;
		--receiver-cycle-delay)
			[[ $# -ge 2 ]] || die "--receiver-cycle-delay requires a value"
			RECEIVER_CYCLE_DELAY="$2"
			shift 2
			;;
		--show-url)
			SHOW_URL=1
			shift
			;;
		--dry-run)
			DRY_RUN=1
			shift
			;;
		--help|-h)
			usage
			exit 0
			;;
		*)
			die "Unknown argument: $1"
			;;
		esac
	done
}

api_base_url() {
	if [[ -n "$CONSOLE_ID" ]]; then
		printf 'https://api.ui.com/v1/connector/consoles/%s/proxy/network/integration' "$CONSOLE_ID"
	else
		printf 'https://%s/proxy/network/integration' "$CONSOLE_IP"
	fi
}

build_port_action_endpoint() {
	local device_id="$1"
	local port_idx="$2"
	printf '%s/v1/sites/%s/devices/%s/interfaces/ports/%s/actions' "$(api_base_url)" "$SITE_ID" "$device_id" "$port_idx"
}

api_get_json() {
	local path="$1"
	local url
	url="$(api_base_url)${path}"

	if [[ "$SHOW_URL" -eq 1 ]]; then
		log "GET ${url}"
	fi

	local body_file http_code
	body_file="$(mktemp)"

	http_code="$({
		curl -sS -o "$body_file" -w '%{http_code}' \
			-X GET "$url" \
			-H 'Accept: application/json' \
			-H "X-API-Key: ${UNIFI_API_KEY}"
	} || true)"

	if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
		cat "$body_file"
		rm -f "$body_file"
		return 0
	fi

	log "API error for GET ${path} status=${http_code}"
	if [[ -s "$body_file" ]]; then
		sed 's/^/  /' "$body_file" >&2 || true
	fi
	rm -f "$body_file"
	return 1
}

list_sites() {
	api_get_json '/v1/sites?limit=200' | python3 - <<'PY'
import json,sys
d=json.load(sys.stdin)
rows=d.get('data',[])
print('siteId\tinternalReference\tname')
for s in rows:
    print(f"{s.get('id','')}\t{s.get('internalReference','')}\t{s.get('name','')}")
PY
}

list_devices() {
	api_get_json "/v1/sites/${SITE_ID}/devices?limit=200" | python3 - <<'PY'
import json,sys
d=json.load(sys.stdin)
rows=d.get('data',[])
print('deviceId\tname\tmodel\tipAddress\tstate')
for r in rows:
    print(f"{r.get('id','')}\t{r.get('name','')}\t{r.get('model','')}\t{r.get('ipAddress','')}\t{r.get('state','')}")
PY
}

list_ports() {
	local device_id="$1"
	api_get_json "/v1/sites/${SITE_ID}/devices/${device_id}" | python3 - <<'PY'
import json,sys
d=json.load(sys.stdin)
ports=((d.get('interfaces') or {}).get('ports') or [])
print('idx\tconnector\tstate\tspeedMbps\tpoe.enabled\tpoe.state\tpoe.standard\tpoe.type')
for p in ports:
    poe=p.get('poe') or {}
    print(f"{p.get('idx','')}\t{p.get('connector','')}\t{p.get('state','')}\t{p.get('speedMbps','')}\t{poe.get('enabled','')}\t{poe.get('state','')}\t{poe.get('standard','')}\t{poe.get('type','')}")
PY
}

split_target() {
	local target="$1"
	local device_id port_idx

	[[ "$target" == *:* ]] || return 1

	device_id="${target%%:*}"
	port_idx="${target##*:}"

	[[ -n "$device_id" && -n "$port_idx" ]] || return 1
	[[ "$port_idx" =~ ^[0-9]+$ ]] || return 1

	printf '%s %s\n' "$device_id" "$port_idx"
}

api_post_action() {
	local device_id="$1"
	local port_idx="$2"
	local action="$3"

	local endpoint
	endpoint="$(build_port_action_endpoint "$device_id" "$port_idx")"

	if [[ "$SHOW_URL" -eq 1 || "$DRY_RUN" -eq 1 ]]; then
		log "POST ${endpoint} action=${action}"
	fi

	if [[ "$DRY_RUN" -eq 1 ]]; then
		return 0
	fi

	local body_file http_code
	body_file="$(mktemp)"

	http_code="$({
		curl -sS -o "$body_file" -w '%{http_code}' \
			-X POST "$endpoint" \
			-H 'Accept: application/json' \
			-H "X-API-Key: ${UNIFI_API_KEY}" \
			-H 'Content-Type: application/json' \
			--data "{\"action\":\"${action}\"}"
	} || true)"

	if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
		rm -f "$body_file"
		return 0
	fi

	log "API error for ${device_id}:${port_idx} action=${action} status=${http_code}"
	if [[ -s "$body_file" ]]; then
		sed 's/^/  /' "$body_file" >&2 || true
	fi
	rm -f "$body_file"
	return 1
}

run_first_success_action() {
	local device_id="$1"
	local port_idx="$2"
	local label="$3"
	shift 3

	local candidate
	for candidate in "$@"; do
		log "${label}: trying action '${candidate}' on ${device_id}:${port_idx}"
		if api_post_action "$device_id" "$port_idx" "$candidate"; then
			log "${label}: succeeded with action '${candidate}' on ${device_id}:${port_idx}"
			return 0
		fi
	done

	return 1
}

main() {
	require_cmd curl
	require_cmd python3

	[[ -f "$ENV_FILE" ]] || die "Env file not found: $ENV_FILE"
	# shellcheck disable=SC1090
	source "$ENV_FILE"
	apply_env_defaults

	parse_args "$@"

	[[ -n "${UNIFI_API_KEY:-}" ]] || die "UNIFI_API_KEY is not set (expected in $ENV_FILE)"

	if [[ -z "$CONSOLE_ID" && -z "$CONSOLE_IP" ]]; then
		die "Set UNIFI_CONSOLE_ID (cloud connector) or UNIFI_CONSOLE_IP (local console)"
	fi

	if [[ "$LIST_SITES" -eq 1 ]]; then
		list_sites
		return 0
	fi

	if [[ "$LIST_DEVICES" -eq 1 ]]; then
		[[ -n "$SITE_ID" ]] || die "UNIFI_SITE_ID or --site-id is required for --list-devices"
		list_devices
		return 0
	fi

	if [[ -n "$LIST_PORTS_DEVICE_ID" ]]; then
		[[ -n "$SITE_ID" ]] || die "UNIFI_SITE_ID or --site-id is required for --list-ports"
		list_ports "$LIST_PORTS_DEVICE_ID"
		return 0
	fi

	# Build legacy target values from structured defaults if explicit targets were not provided.
	if [[ -z "$POE_TARGET_1" && -n "$RADIO_SWITCH_ID" && -n "$RADIO_HUB_PORTIDX" ]]; then
		POE_TARGET_1="${RADIO_SWITCH_ID}:${RADIO_HUB_PORTIDX}"
	fi

	if [[ -z "$POE_TARGET_2" && -n "$RADIO_SWITCH_ID" && -n "$RADIO_DEVICE_PORTIDX" ]]; then
		POE_TARGET_2="${RADIO_SWITCH_ID}:${RADIO_DEVICE_PORTIDX}"
	fi

	if [[ -z "$CYCLE_TARGET" && -n "$RECEIVER_SWITCH_ID" && -n "$RECEIVER_PORTIDX" ]]; then
		CYCLE_TARGET="${RECEIVER_SWITCH_ID}:${RECEIVER_PORTIDX}"
	fi

	[[ -n "$SITE_ID" ]] || die "UNIFI_SITE_ID is required"
	[[ -n "$POE_TARGET_1" ]] || die "UNIFI_POE_TARGET_1 is required (deviceId:portIdx)"
	[[ -n "$POE_TARGET_2" ]] || die "UNIFI_POE_TARGET_2 is required (deviceId:portIdx)"
	[[ -n "$CYCLE_TARGET" ]] || die "UNIFI_CYCLE_TARGET is required (deviceId:portIdx)"
	[[ "$RECEIVER_CYCLE_DELAY" =~ ^[0-9]+$ ]] || die "UNIFI_RECEIVER_CYCLE_DELAY/UNIFI_RECIEVER_CYCLE_DELAY must be an integer"

	local d1 p1 d2 p2 d3 p3
	read -r d1 p1 < <(split_target "$POE_TARGET_1") || die "Invalid UNIFI_POE_TARGET_1: $POE_TARGET_1"
	read -r d2 p2 < <(split_target "$POE_TARGET_2") || die "Invalid UNIFI_POE_TARGET_2: $POE_TARGET_2"
	read -r d3 p3 < <(split_target "$CYCLE_TARGET") || die "Invalid UNIFI_CYCLE_TARGET: $CYCLE_TARGET"

	log "Power-cycling radio targets ${d1}:${p1} and ${d2}:${p2}"
	api_post_action "$d1" "$p1" "$POWER_CYCLE_ACTION" || die "Unable to power cycle ${d1}:${p1}"
	api_post_action "$d2" "$p2" "$POWER_CYCLE_ACTION" || die "Unable to power cycle ${d2}:${p2}"

	if [[ "$RECEIVER_CYCLE_DELAY" -gt 0 ]]; then
		log "Waiting ${RECEIVER_CYCLE_DELAY}s before receiver cycle"
		sleep "$RECEIVER_CYCLE_DELAY"
	fi

	log "Power-cycling final target ${d3}:${p3} with action '${POWER_CYCLE_ACTION}'"
	api_post_action "$d3" "$p3" "$POWER_CYCLE_ACTION" || die "Unable to power cycle ${d3}:${p3}"

	log "Sequence complete"
}

main "$@"
