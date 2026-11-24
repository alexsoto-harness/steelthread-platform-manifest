#!/usr/bin/env bash
# Stub for seeding the integration environment with test data.
# Real version: load the reference datasets into the leased env and return their id.
set -euo pipefail
env_id="${1:?env_id}"
dataset_id="ds-$(date +%Y%m%d)-$(head -c 3 /dev/urandom | od -An -tx1 | tr -d ' \n')"
echo "seeded dataset $dataset_id into $env_id"
printf '{"env_id":"%s","dataset_id":"%s"}\n' "$env_id" "$dataset_id" > seed.json
echo "dataset_id=$dataset_id"
