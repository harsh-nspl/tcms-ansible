#!/bin/bash
set -euo pipefail

# ----------------------
# Required environment variables
# ----------------------
: "${JENKINS_URL:?Please set JENKINS_URL}"
: "${USER:?Please set USER}"
: "${TOKEN:?Please set TOKEN}"
: "${CRED_ID:?Please set CRED_ID}"
: "${CRED_USERNAME:?Please set CRED_USERNAME}"
: "${CRED_PASSWORD:?Please set CRED_PASSWORD}"

# ----------------------
# Create Groovy script
# ----------------------
TMP_GROOVY=$(mktemp)
cat <<EOF > "$TMP_GROOVY"
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList(
    'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
)[0].getStore()

def existing = store.getCredentials(domain).find { it.id == "${CRED_ID}" }
if (existing != null) {
    println("Credential '${CRED_ID}' already exists, updating...")
    store.removeCredentials(domain, existing)
}

def cred = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "${CRED_ID}",
    "Added via script",
    "${CRED_USERNAME}",
    "${CRED_PASSWORD}"
)

store.addCredentials(domain, cred)
println("✅ Username/password credential '${CRED_ID}' added/updated successfully")
EOF

# ----------------------
# Execute Groovy on Jenkins
# ----------------------
CRUMB=$(curl -s -u "$USER:$TOKEN" \
    "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" || true)

if [ -n "$CRUMB" ]; then
    curl -s -X POST "$JENKINS_URL/scriptText" \
        -u "$USER:$TOKEN" \
        -H "$CRUMB" \
        --data-urlencode "script=$(cat "$TMP_GROOVY")"
else
    curl -s -X POST "$JENKINS_URL/scriptText" \
        -u "$USER:$TOKEN" \
        --data-urlencode "script=$(cat "$TMP_GROOVY")"
fi

# ----------------------
# Cleanup
# ----------------------
rm -f "$TMP_GROOVY"