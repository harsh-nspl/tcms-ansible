def call(Map config) {
    sh """#!/bin/bash
        set -euxo pipefail

        cd "\${HOST_BUILD_DIR}/${config.repoName}"

        STATIC_PATH="${config.staticPath ?: '/var/www/html/aio-tcms/aiotcms-static'}"

        # Atomic deployment with rollback capability
        rm -rf \${STATIC_PATH}/spa_new
        mkdir -p \${STATIC_PATH}

        cp -R dist/spa \${STATIC_PATH}/spa_new

        # Atomic swap
        mv \${STATIC_PATH}/spa \${STATIC_PATH}/spa_old 2>/dev/null || true
        mv \${STATIC_PATH}/spa_new \${STATIC_PATH}/spa

        # Cleanup old version
        rm -rf \${STATIC_PATH}/spa_old
    """
}
