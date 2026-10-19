#!/bin/sh
# Blockcheck.cmd tarafindan zapret-win-bundle icindeki cygwin bash ile cagrilir.
# Ayarlar (BATCH, DOMAINS, IPVS ...) Blockcheck.cmd icinde ortam degiskeni olarak verilir.

export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

EXEDIR="$(dirname "$0")"
EXEDIR="$(cd "$EXEDIR"; pwd)"
BC2DIR="$EXEDIR/bundle/zapret-win-bundle-master/blockcheck/zapret2"

"$BC2DIR/blockcheck2.sh" 2>&1 | tee "$EXEDIR/blockcheck2.log"
