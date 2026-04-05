#!/bin/bash

CRUMB=$(curl -s -u "$USER:$TOKEN" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

RESPONSE=$(curl -s -u "$USER:$TOKEN" -H "$CRUMB" \
  "$JENKINS_URL/credentials/store/system/domain/_/credential/$CRED_ID/api/json")

if echo "$RESPONSE" | grep -q "\"id\":\"$CRED_ID\""; then
  echo "exists"
else
  echo "not_exists"
fi