#!/bin/bash
cat ../rebuildamplify/authconfig.addauth.json | jq -c | amplify add auth --headless