#!/bin/bash

BRAND_NAME="${BRAND_NAME:-Rizx Official Store}"
BRAND_TEXT="${BRAND_TEXT:-Protect By Rizx Official}"
CONTACT_TELEGRAM="${CONTACT_TELEGRAM:-@rizxofficial}"

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
NEST_CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/NestController.php"
EGG_CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/EggController.php"

echo "🚀 Memasang Protect 14: Anti Akses Nests (Controller Only)..."
echo ""

inject_protect() {
    local FILE="$1"
    local LABEL="$2"

    if [ ! -f "$FILE" ]; then
        echo "⚠️ File tidak ditemukan: $FILE"
        return 1
    fi

    if grep -q "PROTEKSI_RIZX_NEST" "$FILE"; then
        echo "⚠️ Proteksi sudah ada di $LABEL, skip."
        return 0
    fi

    cp "$FILE" "${FILE}.bak_${TIMESTAMP}"
    echo "📦 Backup $LABEL: ${FILE}.bak_${TIMESTAMP}"

    export INJECT_FILE="$FILE"
    export INJECT_LABEL="$LABEL"
    export INJECT_BRAND="$BRAND_TEXT"

    python3 << 'PYEOF'
import re, os

filepath = os.environ["INJECT_FILE"]
label = os.environ["INJECT_LABEL"]
brand_text = os.environ["INJECT_BRAND"]

with open(filepath, "r") as f:
    content = f.read()

if "PROTEKSI_RIZX_NEST" in content:
    print(f"⚠️ Proteksi sudah ada di {label}")
    exit(0)

if "use Illuminate\\Support\\Facades\\Auth;" not in content:
    content = content.replace(
        "use Pterodactyl\\Http\\Controllers\\Controller;",
        "use Pterodactyl\\Http\\Controllers\\Controller;\nuse Illuminate\\Support\\Facades\\Auth;"
    )

lines = content.split("\n")
new_lines = []
i = 0

while i < len(lines):
    line = lines[i]
    new_lines.append(line)

    if re.search(r'public function (?!__construct)', line):
        j = i + 1
        while j < len(lines) and '{' not in lines[j]:
            new_lines.append(lines[j])
            j += 1

        if j < len(lines) and '{' in lines[j] and j > i:
            new_lines.append(lines[j])
            i = j

        new_lines.append("        // PROTEKSI_RIZX_NEST: Hanya admin ID 1")
        new_lines.append("        if (!Auth::user() || (int) Auth::user()->id !== 1) {")
        new_lines.append("            abort(403, '\u26d4 Akses ditolak! Hanya admin ID 1 yang dapat mengakses menu Nests. \xa9" + brand_text + "');")
        new_lines.append("        }")

    i += 1

with open(filepath, "w") as f:
    f.write("\n".join(new_lines))

print(f"✅ Proteksi berhasil diinjeksi ke {label}")
PYEOF
}

inject_protect "$NEST_CONTROLLER" "NestController"
inject_protect "$EGG_CONTROLLER" "EggController"

echo ""
echo "📋 Verifikasi:"
grep -c "PROTEKSI_RIZX_NEST" "$NEST_CONTROLLER" 2>/dev/null && echo "✅ NestController: OK" || echo "❌ NestController: GAGAL"
grep -c "PROTEKSI_RIZX_NEST" "$EGG_CONTROLLER" 2>/dev/null && echo "✅ EggController: OK" || echo "❌ EggController: GAGAL"

echo ""
echo "==========================================="
echo "✅ Protect 14 selesai!"
echo "==========================================="
echo "🔒 Akses /admin/nests diblock untuk non-ID-1"
echo "🔒 Akses /admin/nests/*/eggs diblock untuk non-ID-1"
echo "📌 Sidebar Nests tetap tampil (hanya controller yang diblock)"
echo "==========================================="
echo ""
echo "⚠️ Untuk uninstall, restore:"
echo "   cp ${NEST_CONTROLLER}.bak_${TIMESTAMP} $NEST_CONTROLLER"
echo "   cp ${EGG_CONTROLLER}.bak_${TIMESTAMP} $EGG_CONTROLLER"
