#!/usr/bin/env bash
#
# Installs the latest "Linux (Headless Server)" build of the godot-ci workflow
# and restarts the testing server. Used by the in-game /deploy admin command,
# which runs `install`, warns players, then runs `restart` through systemd-run.
#
# Setup (one-time):
#   1. Save a GitHub token able to read the repo's Actions artifacts to
#      $TOKEN_FILE, alone in the file. chmod 600 it.
#   2. Set Deploy-Script in the [Deploy] section of the server's credential.cfg
#      (~/.local/share/SourceOfMana/credential.cfg) to this script's full path.
#
# Usage:
#   deploy-server.sh install    # swap in the latest build; exits 3 if it is already installed
#   deploy-server.sh restart    # restart the service and check it stays up

set -euo pipefail

SERVICE_NAME="sourceofmana-testing"
INSTALL_DIR="$HOME/som-testing"
TOKEN_FILE="$HOME/.config/sourceofmana-deploy/token"
BRANCH="master"

REPO="sourceofmana/sourceofmana"
WORKFLOW_FILE="godot-ci.yml"
ARTIFACT_NAME="Linux (Headless Server)"
BUILD_BINARY_NAME="Source of Mana Server.x86_64"
BINARY_NAME="Source of Mana.x86_64"
VERSION_FILE="$INSTALL_DIR/.deployed_version"
EXIT_UP_TO_DATE=3

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
die() { log "ERROR: $*"; exit 1; }

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/sourceofmana-deploy.lock"
flock -n 9 || die "another deploy is already running"

# Install
gh_api() {
	curl -sS --fail --retry 3 \
		-H "Authorization: Bearer $GH_TOKEN" \
		-H "Accept: application/vnd.github+json" \
		"$@"
}

install_build() {
	[[ -s "$TOKEN_FILE" ]] || die "token file $TOKEN_FILE is missing or empty"
	GH_TOKEN="$(tr -d '[:space:]' <"$TOKEN_FILE")"
	local api="https://api.github.com/repos/$REPO/actions"
	local runId runSha runNum artifactUrl="" newestRunNum=""

	while read -r runId runSha runNum; do
		[[ -z "$newestRunNum" ]] && newestRunNum="$runNum"
		artifactUrl="$(gh_api "$api/runs/$runId/artifacts" | jq -r --arg name "$ARTIFACT_NAME" \
			'.artifacts[] | select(.name == $name and .expired == false) | .archive_download_url' | head -n1)"
		[[ -n "$artifactUrl" ]] && break
	done < <(gh_api "$api/workflows/$WORKFLOW_FILE/runs?branch=$BRANCH&event=push&per_page=10" \
		| jq -r '.workflow_runs[] | "\(.id) \(.head_sha) \(.run_number)"')
	[[ -n "$artifactUrl" ]] || die "no '$ARTIFACT_NAME' build found in the last 10 runs on $BRANCH"

	if [[ -f "$VERSION_FILE" && "$(<"$VERSION_FILE")" == "$runSha" ]]; then
		if [[ "$runNum" != "$newestRunNum" ]]; then
			log "Already running the latest available build (commit ${runSha:0:9}), run #$newestRunNum has no server build yet."
		else
			log "Already running the latest build (commit ${runSha:0:9})."
		fi
		exit "$EXIT_UP_TO_DATE"
	fi

	WORK_DIR="$(mktemp -d)"
	trap 'rm -rf "$WORK_DIR" "$INSTALL_DIR.new" "$INSTALL_DIR.old"' EXIT
	log "Downloading run #$runNum (commit ${runSha:0:9})..."
	gh_api -L -o "$WORK_DIR/artifact.zip" "$artifactUrl"
	unzip -q "$WORK_DIR/artifact.zip" -d "$WORK_DIR"

	rm -rf "$INSTALL_DIR.new"
	mkdir -p "$INSTALL_DIR.new"
	tar -xzf "$WORK_DIR/$ARTIFACT_NAME.tar.gz" -C "$INSTALL_DIR.new"
	[[ -f "$INSTALL_DIR.new/$BUILD_BINARY_NAME" ]] || die "'$BUILD_BINARY_NAME' is missing from the build"
	if [[ "$BUILD_BINARY_NAME" != "$BINARY_NAME" ]]; then
		mv "$INSTALL_DIR.new/$BUILD_BINARY_NAME" "$INSTALL_DIR.new/$BINARY_NAME"
	fi
	chmod +x "$INSTALL_DIR.new/$BINARY_NAME"
	if [[ -f "$INSTALL_DIR.new/crashpad_handler" ]]; then
		chmod +x "$INSTALL_DIR.new/crashpad_handler"
	fi
	echo "$runSha" > "$INSTALL_DIR.new/.deployed_version"

	if [[ -d "$INSTALL_DIR" ]]; then
		mv "$INSTALL_DIR" "$INSTALL_DIR.old"
	fi
	mv "$INSTALL_DIR.new" "$INSTALL_DIR"
	log "Installed commit ${runSha:0:9} (run #$runNum), restart pending."
}

# Restart
restart_service() {
	local pid waited=0
	log "Restarting $SERVICE_NAME..."
	systemctl --user stop "$SERVICE_NAME"
	systemctl --user start "$SERVICE_NAME"

	while [[ "$(systemctl --user is-active "$SERVICE_NAME" || true)" != "active" ]]; do
		(( waited >= 30 )) && die "$SERVICE_NAME did not start within 30s, check: journalctl --user -u $SERVICE_NAME -n 50"
		sleep 2
		waited=$((waited + 2))
	done

	pid="$(systemctl --user show -p MainPID --value "$SERVICE_NAME")"
	sleep 10
	[[ "$(systemctl --user show -p MainPID --value "$SERVICE_NAME")" == "$pid" ]] \
		|| die "$SERVICE_NAME crashed within 10s of starting, check: journalctl --user -u $SERVICE_NAME -n 50"
	log "$SERVICE_NAME is up (pid $pid)."
}

case "${1:-}" in
	install) install_build ;;
	restart) restart_service ;;
	*) echo "Usage: $0 install|restart" >&2; exit 1 ;;
esac
