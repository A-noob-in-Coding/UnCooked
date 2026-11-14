#!/usr/bin/env bash
set -euo pipefail

: "${ALB_URL:?need ALB_URL, e.g. http://xxxx.elb.amazonaws.com}"

url="${ALB_URL%/}/health"
echo "GET $url"
for i in $(seq 1 10); do
  if curl -fsS "$url"; then
    echo
    echo "smoke ok (try $i)"
    exit 0
  fi
  echo "try $i failed, sleeping..."
  sleep 15
done

echo "smoke failed"
exit 1
