#!/usr/bin/env bash
# Slip skill helper. stdout is only a share URL (or message text for read).
# Never print owner_token. Do not use curl -f.
set -euo pipefail

SLIP_API="${SLIP_API:-https://slip.viddy.eu.cc}"
SLIP_API="${SLIP_API%/}"
SLIP_UA="slip-skill/1.0"
USER_ID_RE='^[a-z]+-[a-z]+-[0-9]{3}$'
DEFAULT_MAX_CHARS=50000

usage() {
  cat >&2 <<'EOF'
usage:
  slip.sh push              # stdin = note text; stdout = one URL
  slip.sh write <id>        # stdin = note text
  slip.sh read <id>         # stdout = messages, --- separated
  slip.sh create            # empty slip; stdout = one URL (prefer push)
EOF
}

die() {
  local code="$1"
  shift
  printf '%s\n' "$*" >&2
  exit "$code"
}

require_tools() {
  command -v curl >/dev/null 2>&1 || die 2 "need curl"
  if command -v python3 >/dev/null 2>&1; then
    JSON_BIN=python3
  elif command -v node >/dev/null 2>&1; then
    JSON_BIN=node
  else
    die 2 "need python3 or node"
  fi
}

cleanup() {
  [[ -n "${TMPDIR_SLIP:-}" && -d "${TMPDIR_SLIP}" ]] && rm -rf "$TMPDIR_SLIP"
}
TMPDIR_SLIP=""
setup_tmp() {
  TMPDIR_SLIP="$(mktemp -d "${TMPDIR:-/tmp}/slip.XXXXXX")"
  trap cleanup EXIT
}

utf16_len() {
  local file="$1"
  if [[ "$JSON_BIN" == python3 ]]; then
    python3 -c 'import sys
p=sys.argv[1]
s=open(p,encoding="utf-8").read()
print(sum(2 if ord(c)>0xFFFF else 1 for c in s))' "$file"
  else
    node -e 'const fs=require("fs"); process.stdout.write(String(fs.readFileSync(process.argv[1],"utf8").length));' "$file"
  fi
}

is_blank_file() {
  local file="$1"
  if [[ "$JSON_BIN" == python3 ]]; then
    python3 -c 'import sys; s=open(sys.argv[1],encoding="utf-8").read(); sys.exit(0 if not s.strip() else 1)' "$file"
  else
    node -e 'const fs=require("fs"); const s=fs.readFileSync(process.argv[1],"utf8"); process.exit(s.trim() ? 1 : 0);' "$file"
  fi
}

encode_text_json() {
  local infile="$1" outfile="$2"
  if [[ "$JSON_BIN" == python3 ]]; then
    python3 -c 'import json,sys
text=open(sys.argv[1],encoding="utf-8").read()
open(sys.argv[2],"w",encoding="utf-8").write(json.dumps({"text":text},ensure_ascii=False))' "$infile" "$outfile"
  else
    node -e 'const fs=require("fs"); const text=fs.readFileSync(process.argv[1],"utf8"); fs.writeFileSync(process.argv[2], JSON.stringify({text}));' "$infile" "$outfile"
  fi
}

json_get() {
  local file="$1" key="$2"
  if [[ "$JSON_BIN" == python3 ]]; then
    python3 -c 'import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
v=d.get(sys.argv[2])
if v is None:
    sys.exit(1)
print(v)' "$file" "$key"
  else
    node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); const v=d[process.argv[2]]; if(v==null) process.exit(1); process.stdout.write(String(v));' "$file" "$key"
  fi
}

json_error() {
  local file="$1"
  if [[ "$JSON_BIN" == python3 ]]; then
    python3 -c 'import json,sys
raw=open(sys.argv[1],encoding="utf-8",errors="replace").read()
try:
    d=json.loads(raw)
    print(d.get("error") or raw[:200])
except Exception:
    print(raw[:200])' "$file"
  else
    node -e 'const fs=require("fs"); const raw=fs.readFileSync(process.argv[1],"utf8"); try { const d=JSON.parse(raw); process.stdout.write(String(d.error||raw.slice(0,200))); } catch { process.stdout.write(raw.slice(0,200)); }' "$file"
  fi
}

print_messages() {
  local file="$1"
  if [[ "$JSON_BIN" == python3 ]]; then
    python3 -c 'import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
msgs=d.get("messages") or []
out=[]
for m in msgs:
    if isinstance(m,dict) and "text" in m:
        out.append(str(m["text"]))
print("\n---\n".join(out), end="" if not out else "\n")' "$file"
  else
    node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); const msgs=d.messages||[]; const parts=msgs.filter(m=>m&&typeof m.text==="string").map(m=>m.text); process.stdout.write(parts.join("\n---\n")+(parts.length?"\n":""));' "$file"
  fi
}

http_status_exit() {
  local code="$1"
  case "$code" in
    429) echo 3 ;;
    413) echo 4 ;;
    404) echo 5 ;;
    *) echo 1 ;;
  esac
}

request() {
  # request METHOD url [payload_file]
  local method="$1" url="$2" payload="${3:-}"
  local body="$TMPDIR_SLIP/body"
  local args=(
    -sS
    --proto-redir '=https'
    -o "$body"
    -w '%{http_code}'
    -X "$method"
    -H "Accept: application/json"
    -H "User-Agent: ${SLIP_UA}"
  )
  if [[ -n "$payload" ]]; then
    args+=(-H "Content-Type: application/json" --data-binary @"$payload")
  fi
  local code
  set +e
  code="$(curl "${args[@]}" "$url")"
  local curl_ec=$?
  set -e
  if [[ $curl_ec -ne 0 ]]; then
    die 1 "request failed"
  fi
  HTTP_CODE="$code"
  HTTP_BODY="$body"
}

fail_http() {
  local extra="${1:-}"
  local err
  err="$(json_error "$HTTP_BODY")"
  if [[ -n "$extra" ]]; then
    printf '%s %s %s\n' "$HTTP_CODE" "$err" "$extra" >&2
  else
    printf '%s %s\n' "$HTTP_CODE" "$err" >&2
  fi
  exit "$(http_status_exit "$HTTP_CODE")"
}

share_url() {
  printf '%s/%s?utm_source=skill\n' "$SLIP_API" "$1"
}

validate_user_id() {
  local id="$1"
  [[ "$id" =~ $USER_ID_RE ]] || die 2 "invalid id"
}

# Cache max chars once per process. Miss → default. Do not call on every subcommand if unused.
MAX_CHARS=""
load_max_chars() {
  [[ -n "$MAX_CHARS" ]] && return 0
  MAX_CHARS="$DEFAULT_MAX_CHARS"
  request GET "$SLIP_API/api/config" || true
  if [[ "${HTTP_CODE:-}" == 200 ]]; then
    local n
    if n="$(
      if [[ "$JSON_BIN" == python3 ]]; then
        python3 -c 'import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
print((d.get("limits") or {}).get("maxMessageChars") or "")' "$HTTP_BODY"
      else
        node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); const n=(d.limits||{}).maxMessageChars; process.stdout.write(n==null?"":String(n));' "$HTTP_BODY"
      fi
    )" && [[ "$n" =~ ^[0-9]+$ ]] && [[ "$n" -gt 0 ]]; then
      MAX_CHARS="$n"
    fi
  fi
}

check_length() {
  local file="$1"
  load_max_chars
  local n
  n="$(utf16_len "$file")"
  if [[ "$n" -gt "$MAX_CHARS" ]]; then
    die 4 "message too long (${n} > ${MAX_CHARS} UTF-16 code units)"
  fi
}

create_slip() {
  request POST "$SLIP_API/api/slip"
  [[ "$HTTP_CODE" == 200 ]] || fail_http
  local id
  id="$(json_get "$HTTP_BODY" id)" || die 1 "create: missing id"
  # Never echo the create body (it contains owner_token).
  CREATED_ID="$id"
}

write_msg() {
  local id="$1" infile="$2"
  local payload="$TMPDIR_SLIP/payload.json"
  encode_text_json "$infile" "$payload"
  request POST "$SLIP_API/api/slip/${id}/msg" "$payload"
}

cmd_push() {
  local infile="$TMPDIR_SLIP/stdin.txt"
  cat >"$infile"
  if is_blank_file "$infile"; then
    die 2 "empty"
  fi
  check_length "$infile"
  create_slip
  write_msg "$CREATED_ID" "$infile"
  if [[ "$HTTP_CODE" != 200 ]]; then
    if [[ "$HTTP_CODE" == 404 ]]; then
      printf 'created id=%s write_failed: 服务器返回了无法再写入的 id\n' "$CREATED_ID" >&2
    else
      printf 'created id=%s write_failed: %s %s\n' "$CREATED_ID" "$HTTP_CODE" "$(json_error "$HTTP_BODY")" >&2
    fi
    exit "$(http_status_exit "$HTTP_CODE")"
  fi
  share_url "$CREATED_ID"
}

cmd_create() {
  create_slip
  share_url "$CREATED_ID"
}

cmd_write() {
  local id="${1:-}"
  [[ -n "$id" ]] || die 2 "missing id"
  validate_user_id "$id"
  local infile="$TMPDIR_SLIP/stdin.txt"
  cat >"$infile"
  if is_blank_file "$infile"; then
    die 2 "empty"
  fi
  check_length "$infile"
  write_msg "$id" "$infile"
  [[ "$HTTP_CODE" == 200 ]] || fail_http
}

cmd_read() {
  local id="${1:-}"
  [[ -n "$id" ]] || die 2 "missing id"
  validate_user_id "$id"
  request GET "$SLIP_API/api/slip/${id}"
  [[ "$HTTP_CODE" == 200 ]] || fail_http
  print_messages "$HTTP_BODY"
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    -h|--help|"") usage; exit 2 ;;
    push|create|write|read) ;;
    *) usage; exit 2 ;;
  esac
  require_tools
  setup_tmp
  shift || true
  case "$cmd" in
    push) cmd_push ;;
    create) cmd_create ;;
    write) cmd_write "${1:-}" ;;
    read) cmd_read "${1:-}" ;;
  esac
}

main "$@"
