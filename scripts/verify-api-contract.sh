#!/usr/bin/env bash
#
# 実 Rails API のレスポンス構造を、フロント (matcha-to-jinja) の契約正本である
# fixtures から生成したキーパス集合と突き合わせて、ドリフトを検出する。
#
# 自己完結版: 期待キーパスをスクリプト内に埋め込んでいるため、matcha-to-jinja の
#            fixtures をディスクから読まない。greentea_temple 単体で動く。
#            （埋め込み値は matcha-to-jinja の
#             src/lib/api/__tests__/fixtures/*.json から生成した正本）
#
# 比較方法:
#   各レスポンスを「値を無視したキーパス集合」に正規化し、期待値と diff する。
#   - MISSING : 期待値にあって実レスポンスに無いキー（フィールド欠落 / 命名ズレ）
#               ※ 配列が空のときは中身のキーパスが出ないため誤検知し得る → データを入れて確認
#   - EXTRA   : 実レスポンスにあって期待値に無いキー（Rails が余分に返している）
#
# jq idiom 注意:
#   paths(scalars) は値が false / null のリーフを黙って落とす（select が値自体を
#   条件と解釈するため）。closed / owned_by_current_user 等の false 値が消えて
#   検出漏れになるので、ここでは type ベースの正規化を使う。
#
# 使い方:
#   bin/rails server -p 3001            # 別ターミナルで Rails を起動
#   ./scripts/verify-api-contract.sh
#
# 環境変数:
#   BASE       既定 http://localhost:3001/api/v1
#   JWT        指定すると認証必須エンドポイント (current_user) も検証
#   GID/TID    詳細で叩く greentea_id / temple_id（既定 1 / 1）
#   LAT/LNG/RADIUS  nearby 用（既定 35.0036 / 135.7752 / 1.5[km]）

set -uo pipefail

BASE="${BASE:-http://localhost:3001/api/v1}"
GID="${GID:-1}"
TID="${TID:-1}"
LAT="${LAT:-35.0036}"
LNG="${LNG:-135.7752}"
RADIUS="${RADIUS:-1.5}"

command -v jq >/dev/null || { echo "jq が必要です (apt install jq / brew install jq)"; exit 1; }

pass=0; drift=0; fail=0

# JSON を「値を無視した正規化キーパス集合」に変換。
# paths(scalars) の false/null 脱落バグを避け、type ベースで葉を選ぶ。
# 配列インデックスは [] に畳む。
keypaths() {
  jq -r 'paths(type!="object" and type!="array")
         | map(if type=="number" then "[]" else tostring end)
         | join(".")' | sort -u
}

# 各エンドポイントの期待キーパス（フロント fixtures から生成した正本）
expected_keypaths() {
  case "$1" in
  greenteas.list)
    cat <<'EOF'
greenteas.[].access
greenteas.[].address
greenteas.[].business_hours
greenteas.[].closed
greenteas.[].description
greenteas.[].genres.[].id
greenteas.[].genres.[].name
greenteas.[].holiday
greenteas.[].homepage
greenteas.[].id
greenteas.[].img
greenteas.[].latitude
greenteas.[].likes_count
greenteas.[].longitude
greenteas.[].name
greenteas.[].phone_number
meta.current_page
meta.total_count
meta.total_pages
EOF
    ;;
  greenteas.show)
    cat <<'EOF'
greentea.access
greentea.address
greentea.business_hours
greentea.closed
greentea.comments.[].body
greentea.comments.[].created_at
greentea.comments.[].id
greentea.comments.[].owned_by_current_user
greentea.comments.[].user.id
greentea.comments.[].user.name
greentea.description
greentea.genres.[].id
greentea.genres.[].name
greentea.holiday
greentea.homepage
greentea.id
greentea.img
greentea.latitude
greentea.liked_by_current_user
greentea.likes_count
greentea.longitude
greentea.name
greentea.nearby_temples.[].distance_meters
greentea.nearby_temples.[].id
greentea.nearby_temples.[].latitude
greentea.nearby_temples.[].longitude
greentea.nearby_temples.[].name
greentea.phone_number
EOF
    ;;
  temples.list)
    cat <<'EOF'
meta.current_page
meta.total_count
meta.total_pages
temples.[].access
temples.[].address
temples.[].areas.[].id
temples.[].areas.[].name
temples.[].business_hours
temples.[].description
temples.[].holiday
temples.[].homepage
temples.[].id
temples.[].img
temples.[].latitude
temples.[].likes_count
temples.[].longitude
temples.[].name
temples.[].phone_number
EOF
    ;;
  temples.show)
    cat <<'EOF'
temple.access
temple.address
temple.areas.[].id
temple.areas.[].name
temple.business_hours
temple.comments.[].body
temple.comments.[].created_at
temple.comments.[].id
temple.comments.[].owned_by_current_user
temple.comments.[].user.id
temple.comments.[].user.name
temple.description
temple.holiday
temple.homepage
temple.id
temple.img
temple.latitude
temple.liked_by_current_user
temple.likes_count
temple.longitude
temple.name
temple.nearby_greenteas.[].distance_meters
temple.nearby_greenteas.[].id
temple.nearby_greenteas.[].latitude
temple.nearby_greenteas.[].longitude
temple.nearby_greenteas.[].name
temple.phone_number
EOF
    ;;
  genres.list)
    cat <<'EOF'
genres.[].id
genres.[].name
EOF
    ;;
  areas.list)
    cat <<'EOF'
areas.[].id
areas.[].name
EOF
    ;;
  nearby)
    cat <<'EOF'
greenteas.[].distance_meters
greenteas.[].id
greenteas.[].latitude
greenteas.[].longitude
greenteas.[].name
temples.[].distance_meters
temples.[].id
temples.[].latitude
temples.[].longitude
temples.[].name
EOF
    ;;
  current_user)
    cat <<'EOF'
user.id
user.name
EOF
    ;;
  esac
}

# $1=表示名 $2=method $3=path $4=expectedキー $5=auth(1なら要JWT)
check() {
  local name="$1" method="$2" path="$3" expkey="$4" need_auth="${5:-0}"

  if [[ "$need_auth" == "1" && -z "${JWT:-}" ]]; then
    printf "  SKIP  %-26s (JWT 未設定)\n" "$name"
    return
  fi

  local hdr=(); [[ -n "${JWT:-}" ]] && hdr=(-H "Authorization: Bearer $JWT")

  local body code
  body="$(curl -sS -m 15 -X "$method" "${hdr[@]}" -w $'\n%{http_code}' "$BASE$path" 2>/dev/null)"
  code="${body##*$'\n'}"
  body="${body%$'\n'*}"

  if [[ "$code" != "200" ]]; then
    printf "  FAIL  %-26s HTTP %s\n" "$name" "$code"
    fail=$((fail+1)); return
  fi
  if ! echo "$body" | jq -e . >/dev/null 2>&1; then
    printf "  FAIL  %-26s 非JSONレスポンス\n" "$name"
    fail=$((fail+1)); return
  fi

  local live exp missing extra
  live="$(echo "$body" | keypaths)"
  exp="$(expected_keypaths "$expkey")"

  missing="$(comm -23 <(echo "$exp") <(echo "$live"))"
  extra="$(comm -13 <(echo "$exp") <(echo "$live"))"

  if [[ -z "$missing" && -z "$extra" ]]; then
    printf "  PASS  %-26s\n" "$name"
    pass=$((pass+1))
  else
    printf "  DRIFT %-26s\n" "$name"
    [[ -n "$missing" ]] && echo "$missing" | sed 's/^/          - MISSING /'
    [[ -n "$extra"   ]] && echo "$extra"   | sed 's/^/          + EXTRA   /'
    drift=$((drift+1))
  fi
}

echo "BASE = $BASE"
echo
echo "[読み取り系]"
check "GET /greenteas"      GET "/greenteas"      greenteas.list
check "GET /greenteas/:id"  GET "/greenteas/$GID" greenteas.show
check "GET /temples"        GET "/temples"        temples.list
check "GET /temples/:id"    GET "/temples/$TID"   temples.show
check "GET /genres"         GET "/genres"         genres.list
check "GET /areas"          GET "/areas"          areas.list
check "GET /nearby"         GET "/nearby?lat=$LAT&lng=$LNG&radius=$RADIUS" nearby

echo
echo "[認証系] (JWT 設定時のみ)"
check "GET /current_user"   GET "/current_user"   current_user 1

echo
echo "----------------------------------------"
echo "PASS=$pass  DRIFT=$drift  FAIL=$fail"
echo
echo "注意:"
echo " - DRIFT の MISSING は配列が空（コメント/いいね0件等）でも出ます。データを入れて再確認を。"
echo " - 書き込み系 (likes/comments POST·DELETE, POST /auth/:provider) は副作用があるため自動検証から除外。"

[[ $fail -gt 0 || $drift -gt 0 ]] && exit 1 || exit 0
