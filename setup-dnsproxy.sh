#!/usr/bin/env bash
set -euo pipefail

# !! AI generated, proceed with caution !!
# Improved installer for cloudflared proxy-dns systemd service(s)
# - Detects architecture and downloads the matching cloudflared release
# - Accepts configurable upstream URLs (one or many)
# - Installs cloudflared to /usr/local/bin
# - Creates one systemd unit per upstream and enables/starts them
#
# Usage examples:
#  Interactive prompt: sudo /usr/local/bin/setup-dnsproxy.sh
#  Non-interactive with two upstreams:
#    sudo /usr/local/bin/setup-dnsproxy.sh --upstream https://a.example/dns-query --upstream https://b.example/dns-query
#  Dry-run (no install/start): ./setup-dnsproxy.sh --dry-run --upstream ...

DEFAULT_PORT=5335
SERVICE_PREFIX=cloudflared-proxy-dns
DRY_RUN=0
PORT=$DEFAULT_PORT
ARCH_OVERRIDE=""
SERVICES=()

usage() {
	cat <<EOF
Usage: $0 [options]

Options:
	--upstream URL        Add an upstream DoH URL. Repeatable (at least one required).
	--port PORT           Port for proxy-dns (default: $DEFAULT_PORT)
	--service-prefix NAME Prefix for created systemd services (default: $SERVICE_PREFIX)
	--arch ARCH           Override architecture mapping (amd64, arm64, armv7, 386)
	--dry-run             Show actions but do not install or start services
	-h, --help            Show this help

Examples:
	$0 --upstream https://example.com/dns-query --upstream https://other/dns-query
EOF
}

if [ "$#" -eq 0 ]; then
	usage
fi

while [ "$#" -gt 0 ]; do
	case "$1" in
		--upstream)
			shift
			[ -z "${1-}" ] && echo "Missing value for --upstream" >&2 && exit 2
			SERVICES+=("$1")
			shift
			;;
		--port)
			PORT="$2"; shift 2
			;;
		--service-prefix)
			SERVICE_PREFIX="$2"; shift 2
			;;
		--arch)
			ARCH_OVERRIDE="$2"; shift 2
			;;
		--dry-run)
			DRY_RUN=1; shift
			;;
		-h|--help)
			usage; exit 0
			;;
		*)
			echo "Unknown arg: $1" >&2; usage; exit 2
			;;
	esac
done

if [ "${#SERVICES[@]}" -eq 0 ]; then
	echo "No upstream provided. Please supply at least one --upstream URL." >&2
	exit 2
fi

if [ "$(uname -s)" != "Linux" ]; then
	echo "This installer targets Linux with systemd. Exiting." >&2
	exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
	echo "systemd (systemctl) not found. This script requires systemd." >&2
	exit 1
fi

arch_from_uname() {
	local u arch
	u=$(uname -m)
	case "$u" in
		x86_64|amd64) arch=amd64 ;;
		aarch64|arm64) arch=arm64 ;;
		armv7l|armv7) arch=armv7 ;;
		i386|i686) arch=386 ;;
		*) arch="$u" ;;
	esac
	echo "$arch"
}

ARCH=${ARCH_OVERRIDE:-$(arch_from_uname)}
echo "Detected architecture: $ARCH"

# Construct candidate filenames to try (deb first, then generic binary)
TRY_FILES=(
	"cloudflared-linux-${ARCH}.deb"
	"cloudflared-linux-${ARCH}.tar.gz"
	"cloudflared-linux-${ARCH}"
)

DOWNLOAD_DIR="/tmp/cloudflared-install-$$"
mkdir -p "$DOWNLOAD_DIR"

download_asset() {
	local name dest url
	for name in "${TRY_FILES[@]}"; do
		url="https://github.com/cloudflare/cloudflared/releases/latest/download/${name}"
		dest="$DOWNLOAD_DIR/$name"
		echo "Trying to download $name from $url"
		if curl -fL --retry 3 --retry-delay 2 --location --progress-bar -o "$dest" "$url"; then
			echo "Downloaded $name to $dest"
			echo "$dest"
			return 0
		else
			echo "Not available: $name (HTTP error or missing asset)." >&2
			rm -f "$dest" || true
		fi
	done
	return 1
}

ASSET_PATH=$(download_asset) || { echo "Failed to find a matching cloudflared asset for arch $ARCH" >&2; exit 1; }

install_binary() {
	local path="$1"
	if [[ "$path" == *.deb ]]; then
		if command -v dpkg >/dev/null 2>&1; then
			echo "Installing .deb via dpkg"
			if [ "$DRY_RUN" -eq 0 ]; then
				sudo dpkg -i "$path"
			else
				echo "DRY RUN: sudo dpkg -i $path"
			fi
		else
			echo "dpkg not found; extracting deb contents"
			if [ "$DRY_RUN" -eq 0 ]; then
				tmpdir=$(mktemp -d)
				(cd "$tmpdir" && ar x "$path" && tar -xzf data.tar.*)
				# find binary; install to /usr/local/bin
				bin=$(find "$tmpdir" -type f -name cloudflared -perm /u=x 2>/dev/null | head -n1)
				if [ -z "$bin" ]; then echo "cloudflared binary not found inside deb" >&2; return 1; fi
				sudo install -m 0755 "$bin" /usr/local/bin/cloudflared
				rm -rf "$tmpdir"
			else
				echo "DRY RUN: would extract deb and install cloudflared to /usr/local/bin"
			fi
		fi
	else
		# treat as raw binary or tarball
		if [[ "$path" == *.tar.gz ]]; then
			echo "Extracting tarball and installing binary"
			if [ "$DRY_RUN" -eq 0 ]; then
				tmpdir=$(mktemp -d)
				tar -xzf "$path" -C "$tmpdir"
				bin=$(find "$tmpdir" -type f -name cloudflared -perm /u=x 2>/dev/null | head -n1)
				if [ -z "$bin" ]; then echo "cloudflared binary not found inside tarball" >&2; return 1; fi
				sudo install -m 0755 "$bin" /usr/local/bin/cloudflared
				rm -rf "$tmpdir"
			else
				echo "DRY RUN: would extract $path and install cloudflared to /usr/local/bin"
			fi
		else
			# assume this is a raw binary
			echo "Installing raw binary to /usr/local/bin/cloudflared"
			if [ "$DRY_RUN" -eq 0 ]; then
				sudo install -m 0755 "$path" /usr/local/bin/cloudflared
			else
				echo "DRY RUN: sudo install -m 0755 $path /usr/local/bin/cloudflared"
			fi
		fi
	fi
}

if [ "$DRY_RUN" -eq 1 ]; then
	echo "DRY RUN enabled: no changes will be made"
fi

install_binary "$ASSET_PATH"

if [ "$DRY_RUN" -eq 0 ]; then
	if ! command -v /usr/local/bin/cloudflared >/dev/null 2>&1; then
		echo "Error: cloudflared not found at /usr/local/bin/cloudflared after install" >&2
		exit 1
	fi
fi

create_unit_and_start() {
	local upstream="$1"
	local idx="$2"
	local name="${SERVICE_PREFIX}"
	if [ "${#SERVICES[@]}" -gt 1 ]; then
		name="${SERVICE_PREFIX}-${idx}"
	fi
	unit_path="/etc/systemd/system/${name}.service"

	cat > /tmp/${name}.unit <<EOF
[Unit]
Description=DNS over HTTPS (DoH) proxy client (${upstream})
Wants=network-online.target nss-lookup.target
Before=nss-lookup.target

[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
DynamicUser=yes
ExecStart=/usr/local/bin/cloudflared proxy-dns --upstream ${upstream} --address 0.0.0.0 --port ${PORT} --max-upstream-conns 0

[Install]
WantedBy=multi-user.target
EOF

	echo "Writing unit to ${unit_path}"
	if [ "$DRY_RUN" -eq 0 ]; then
		sudo mv /tmp/${name}.unit "$unit_path"
		sudo systemctl daemon-reload
		sudo systemctl enable "$name"
		sudo systemctl restart "$name"
		sudo systemctl status --no-pager --lines=5 "$name" || true
	else
		echo "DRY RUN: sudo mv /tmp/${name}.unit ${unit_path}"
		echo "DRY RUN: sudo systemctl enable ${name}"
		echo "DRY RUN: sudo systemctl restart ${name}"
	fi
}

idx=1
for up in "${SERVICES[@]}"; do
	echo "Configuring service for upstream: $up"
	create_unit_and_start "$up" "$idx"
	idx=$((idx+1))
done

echo "Done. Installed cloudflared and configured ${#SERVICES[@]} service(s)."
