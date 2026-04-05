def call(Map config) {
    withCredentials([
        usernamePassword(
            credentialsId: 'forge-credentials',
            usernameVariable: 'FORGE_EMAIL',
            passwordVariable: 'FORGE_API_TOKEN'
        )
    ]) {
        sh """#!/bin/bash
            set -euxo pipefail

            cd "\${HOST_BUILD_DIR}/${config.repoName}"

            # Build Forge app
            npm run build-forge

            rm -rf etc/forge/static/spa
            mkdir -p etc/forge/static
            cp -R dist/spa etc/forge/static/

            # Deploy
            export SKIP_BUILD=true
            ./etc/forge/deploy-local.sh ${config.forgeEnv ?: 'development-new'}
        """
    }
}
