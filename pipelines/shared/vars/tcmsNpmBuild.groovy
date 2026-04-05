def call(Map config) {
    def org = config.org ?: 'harshiet'

    sshagent(['bitbucket-ssh-key']) {
        sh """#!/bin/bash
            set -euxo pipefail

            mkdir -p "\${HOST_BUILD_DIR}"
            cd "\${HOST_BUILD_DIR}"

            # Clone or update main repo
            if [ ! -d "${config.repoName}" ]; then
                git clone "git@bitbucket.org:${org}/${config.repoName}.git"
            fi

            cd "${config.repoName}"
            git fetch --all --prune
            git checkout -B "\${BRANCH}" "origin/\${BRANCH}"
            git reset --hard "origin/\${BRANCH}"

            # Clone config repo if specified
            if [ -n "${config.configRepo ?: ''}" ]; then
                cd "\${HOST_BUILD_DIR}"
                if [ ! -d "${config.configRepo}" ]; then
                    git clone "git@bitbucket.org:${org}/${config.configRepo}.git"
                fi
                cd "${config.configRepo}"
                git fetch origin
                git checkout master
                git reset --hard origin/master
            fi

            # Build
            cd "\${HOST_BUILD_DIR}/${config.repoName}"
            npm ci --cache "\${HOST_BUILD_DIR}/.npm-cache-${config.repoName}"
            npm run ${config.buildScript ?: 'build'}
        """
    }
}
