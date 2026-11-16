#!/usr/bin/env bash
# Construit l'ISO live EPIVÍOSI dans ./result/iso/.
set -euo pipefail
cd "$(dirname "$0")/.."
nix build .#iso --print-build-logs "$@"
ls -lh result/iso/*.iso
