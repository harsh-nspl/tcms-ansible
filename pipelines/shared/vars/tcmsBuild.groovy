def call(Map config) {
    def org = config.org ?: 'harshiet'
    sshagent(['bitbucket-ssh-key']) {
        sh """#!/bin/bash
            set -euxo pipefail
            mkdir -p "\${HOST_BUILD_DIR}"
            cd "\${HOST_BUILD_DIR}"

            if [ ! -d "${config.repoName}" ]; then
                git clone "git@bitbucket.org:${org}/${config.repoName}.git"
            fi

            cd "${config.repoName}"
            git fetch --all --tags --prune
            git checkout "\${BRANCH}" || git checkout -b "\${BRANCH}" "origin/\${BRANCH}"
            git reset --hard "origin/\${BRANCH}"

            chmod +x mvnw
            ${config.buildCommand}
        """
    }
}
