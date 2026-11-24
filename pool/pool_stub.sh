#!/usr/bin/env bash
# Fake environment pool. Mimics the request/release contract of the real pool API.
#
#   pool_stub.sh request <execution_id> <wait_rounds> <attempt>
#       Returns "not_yet" (exit 1) while attempt < wait_rounds, then leases an env.
#       Prints KEY=VALUE lines: env_id, endpoint, release_token, lease_expiry.
#   pool_stub.sh release <env_id> <release_token> <clean|dirty> [candidate_sha]
#       Prints env_release=<clean|dirty>.
#   pool_stub.sh list
#       Prints one line per active lease: <env_id> <release_token> <execution_id> <leased_at>.
#
# Real version: replace each function body with a call to the pool API.
#
# Lease state:
#   - If GH_TOKEN and POOL_STATE_REPO (owner/name) are set, leases live in leases.json on
#     branch pool-state of that repo (GitHub contents API). Any delegate pod sees the same
#     state, so S5 and the reaper work wherever they run.
#   - Otherwise leases live in $POOL_STATE_FILE (default /tmp/steelthread_pool.json).
# Needs bash, jq, curl, base64. No python.
set -euo pipefail
STATE="${POOL_STATE_FILE:-/tmp/steelthread_pool.json}"
BRANCH="${POOL_STATE_BRANCH:-pool-state}"
remote() { [ -n "${GH_TOKEN:-}" ] && [ -n "${POOL_STATE_REPO:-}" ]; }
api() { curl -fsS -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" "$@"; }
URL="https://api.github.com/repos/${POOL_STATE_REPO:-none}/contents/leases.json"

load() {  # prints state JSON; sets STATE_SHA for remote
  if remote; then
    resp=$(api "$URL?ref=$BRANCH")
    STATE_SHA=$(jq -r .sha <<<"$resp")
    jq -r '.content | gsub("\n";"") | @base64d' <<<"$resp"
  else
    [ -f "$STATE" ] || echo '{}' > "$STATE"
    cat "$STATE"
  fi
}
save() {  # $1 = new state JSON, $2 = commit message
  if remote; then
    body=$(jq -n --arg m "$2" --arg c "$(printf '%s\n' "$1" | base64 | tr -d '\n')" \
                 --arg s "$STATE_SHA" --arg b "$BRANCH" '{message:$m,content:$c,sha:$s,branch:$b}')
    api -X PUT "$URL" -d "$body" >/dev/null
  else
    printf '%s\n' "$1" > "$STATE"
  fi
}

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
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    expiry="$(date -u -d '+4 hours' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+4H +%Y-%m-%dT%H:%M:%SZ)"
    STATE_SHA=""; s=$(load)
    s=$(jq -c --arg e "$env_id" --arg t "$token" --arg x "$exec_id" --arg n "$now" --arg l "$expiry" \
          '.[$e]={release_token:$t,execution_id:$x,leased_at:$n,lease_expiry:$l}' <<<"$s")
    save "$s" "pool: lease $env_id to $exec_id"
    echo "env_id=$env_id"
    echo "endpoint=https://$env_id.steelthread.example"
    echo "release_token=$token"
    echo "lease_expiry=$expiry"
    ;;
  release)
    env_id="$1"; token="$2"; outcome="$3"; sha="${4:-unknown}"
    STATE_SHA=""; s=$(load)
    held=$(jq -r --arg e "$env_id" '.[$e].release_token // ""' <<<"$s")
    if [ -z "$held" ]; then
      echo "pool: $env_id has no active lease (already released?)"
    elif [ "$held" != "$token" ]; then
      echo "pool: release token does not match lease for $env_id" >&2; exit 1
    else
      save "$(jq -c --arg e "$env_id" 'del(.[$e])' <<<"$s")" "pool: release $env_id ($outcome)"
    fi
    echo "pool: released $env_id as $outcome (candidate $sha)"
    echo "env_release=$outcome"
    ;;
  list)
    STATE_SHA=""; load | jq -r 'to_entries[] | "\(.key) \(.value.release_token) \(.value.execution_id) \(.value.leased_at // "-")"'
    ;;
  *) echo "usage: $0 request|release|list ..." >&2; exit 2;;
esac
