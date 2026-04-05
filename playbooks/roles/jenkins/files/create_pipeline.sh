#!/bin/bash
set -euo pipefail

: "${JENKINS_URL:?Please set JENKINS_URL environment variable}"
: "${USER:?Please set USER environment variable}"
: "${TOKEN:?Please set TOKEN environment variable}"
: "${JOB_NAME:?Please set JOB_NAME}"
: "${SCRIPT_PATH:?Please set SCRIPT_PATH}"
: "${REPO_URL:?Please set REPO_URL}"
: "${CREDENTIAL_ID:?Please set CREDENTIAL_ID}"
BRANCH="${BRANCH:-*/master}"

TMP_GROOVY=$(mktemp)

cat <<EOF > "$TMP_GROOVY"
import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*

def jobName = "${JOB_NAME}"
def repoUrl = "${REPO_URL}"
def branch = "${BRANCH}"
def scriptPath = "${SCRIPT_PATH}"
def credentialsId = "${CREDENTIAL_ID}"

def job = Jenkins.instance.getItem(jobName)
if (job == null) {
    job = Jenkins.instance.createProject(WorkflowJob, jobName)
    println("Creating job: " + jobName)
} else {
    println("Updating job: " + jobName)
}

def scm = new GitSCM(
    [new UserRemoteConfig(repoUrl, null, null, credentialsId)],
    [new BranchSpec(branch)],
    false, [], null, null, []
)

def definition = new CpsScmFlowDefinition(scm, scriptPath)
definition.setLightweight(true)

job.setDefinition(definition)
job.save()
println("✅ Pipeline ready: " + jobName)
EOF

# --- CSRF crumb ---
CRUMB=$(curl -s -u "$USER:$TOKEN" \
  "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)" || true)

# --- Execute Groovy ---
if [ -n "$CRUMB" ]; then
  curl -s -X POST "$JENKINS_URL/scriptText" -u "$USER:$TOKEN" -H "$CRUMB" \
    --data-urlencode "script=$(cat "$TMP_GROOVY")"
else
  curl -s -X POST "$JENKINS_URL/scriptText" -u "$USER:$TOKEN" \
    --data-urlencode "script=$(cat "$TMP_GROOVY")"
fi

rm -f "$TMP_GROOVY"
echo "🎉 Pipeline '$JOB_NAME' created/updated with credential '$CREDENTIAL_ID'"