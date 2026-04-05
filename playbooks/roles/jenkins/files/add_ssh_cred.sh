#!/bin/bash
set -euo pipefail

: "${JENKINS_URL:?Please set JENKINS_URL}"
: "${USER:?Please set USER}"
: "${TOKEN:?Please set TOKEN}"
: "${CRED_ID:?Please set CRED_ID}"
: "${SSH_USER:?Please set SSH_USER}"
: "${PRIVATE_KEY_FILE:?Please set PRIVATE_KEY_FILE}"

PRIVATE_KEY_ESCAPED=$(sed ':a;N;$!ba;s/\n/\\n/g' "$PRIVATE_KEY_FILE")

TMP_GROOVY=$(mktemp)

cat <<EOF > "$TMP_GROOVY"
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList(
    'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
)[0].getStore()

def existing = store.getCredentials(domain).find { it.id == "${CRED_ID}" }
if (existing != null) {
    println("Credential '${CRED_ID}' already exists, updating...")
    store.removeCredentials(domain, existing)
}

def privateKeyDecoded = """${PRIVATE_KEY_ESCAPED}""".replace("\\n", "\n")

def cred = new BasicSSHUserPrivateKey(
    CredentialsScope.GLOBAL,
    "${CRED_ID}",
    "${SSH_USER}",
    new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(privateKeyDecoded),
    "",
    "Added via script"
)

store.addCredentials(domain, cred)
println("SUCCESS: Credential added")
EOF

CRUMB=$(curl -s -u "$USER:$TOKEN" \
    "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" || true)

echo "CRUMB $CRUMB"
echo "---- Executing Groovy script on Jenkins ----"

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$JENKINS_URL/scriptText" \
    -u "$USER:$TOKEN" \
    ${CRUMB:+-H "$CRUMB"} \
    --data-urlencode "script=$(cat "$TMP_GROOVY")")

echo "$RESPONSE"

rm -f "$TMP_GROOVY"