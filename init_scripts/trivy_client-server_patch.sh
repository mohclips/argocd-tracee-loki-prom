#!/bin/bash

TRIVY_SERVER_URL=http://172.30.5.31:8888

kubectl patch cm starboard-trivy-config -n starboard \
  --type merge \
  -p "$(cat <<EOF
{
  "data": {
    "trivy.mode":      "ClientServer",
    "trivy.serverURL": "$TRIVY_SERVER_URL"
  }
}
EOF
)"




