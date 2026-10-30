#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Executar como root: sudo bash deploy/vm/setup.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="/opt/odsoft"

if ! id -u odsoft >/dev/null 2>&1; then
    useradd --system --home "$ROOT" --shell /usr/sbin/nologin odsoft
fi

install -d -m 755 -o odsoft -g odsoft "$ROOT"
install -d -m 755 -o odsoft -g odsoft "$ROOT/releases" "$ROOT/logs"
install -d -m 755 -o odsoft -g odsoft "$ROOT/data" "$ROOT/data/dev" "$ROOT/data/staging" "$ROOT/data/prod"

install -m 644 "$SCRIPT_DIR"/odsoft-dev.service "$SCRIPT_DIR"/odsoft-staging.service "$SCRIPT_DIR"/odsoft-prod.service /etc/systemd/system/
install -m 755 "$SCRIPT_DIR"/deploy.sh /usr/local/bin/odsoft-deploy

cat > /etc/sudoers.d/odsoft-jenkins <<'EOF'
jenkins ALL=(root) NOPASSWD: /usr/local/bin/odsoft-deploy
EOF
chmod 440 /etc/sudoers.d/odsoft-jenkins
visudo -cf /etc/sudoers.d/odsoft-jenkins >/dev/null

systemctl daemon-reload
systemctl enable odsoft-dev odsoft-staging odsoft-prod

echo "SETUP_OK"
