#!/bin/bash

# Mevcut dosyaya göre konumlandırma
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR/modules"

chmod +x updater.sh
./updater.sh
