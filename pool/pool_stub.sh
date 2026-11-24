#!/usr/bin/env bash
# Fake environment pool. Mimics the request/release contract of the real pool API.
#
#   pool_stub.sh request <execution_id> <wait_rounds> <attempt>
#       Returns "not_yet" (exit 1) while attempt < wait_rounds, then leases an env.
#       Prints KEY=VALUE lines: env_id, endpoint, release_token, lease_expiry.
#   pool_stub.sh release <env_id> <release_token> <clean|dirty> [candidate_sha]
#       Prints env_release=<clean|dirty>.
#   pool_stub.sh list
#       Prints one line per active lease: <env_id> <release_token> <execution_id>.
#
# Real version: replace each function body with a call to the pool API.
# Lease state lives in $POOL_STATE_FILE (default /tmp/steelthread_pool.json).
set -euo pipefail
STATE="${POOL_STATE_FILE:-/tmp/steelthread_pool.json}"
[ -f "$STATE" ] || echo '{}' > "$STATE"

cmd="${1:-}"; shift || true
case "$cmd" in
  request)
    exec_id="$1"; wait_rounds="${2:-0}"; attempt="${3:-0}"
    if [ "$attempt" -lt "$wait_rounds" ]; then
      echo "pool: not_yet (attempt $attempt of $wait_rounds waits)"
      exit 1
    fi
    env_id="intt-$(date +%s | tail -c 5)"
    token="rt-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    expiry="$(date -u -d '+4 hours' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
    python3 - "$STATE" "$env_id" "$token" "$exec_id" <<'PY'
import json,sys
p,e,t,x=sys.argv[1:]
s=json.load(open(p)); s[e]={"release_token":t,"execution_id":x}
json.dump(s,open(p,"w"))
PY
    echo "env_id=$env_id"
    echo "endpoint=https://$env_id.steelthread.example"
    echo "release_token=$token"
    echo "lease_expiry=$expiry"
    ;;
  release)
    env_id="$1"; token="$2"; outcome="$3"; sha="${4:-unknown}"
    python3 - "$STATE" "$env_id" <<'PY'
import json,sys
p,e=sys.argv[1:]
s=json.load(open(p)); s.pop(e,None); json.dump(s,open(p,"w"))
PY
    echo "pool: released $env_id as $outcome (candidate $sha)"
    echo "env_release=$outcome"
    ;;
  list)
    python3 - "$STATE" <<'PY'
import json,sys
for e,v in json.load(open(sys.argv[1])).items():
    print(e, v["release_token"], v["execution_id"])
PY
    ;;
  *) echo "usage: $0 request|release|list ..." >&2; exit 2;;
esac
