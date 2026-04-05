def call(Map config) {
    sshagent(['ssh-key']) {
        withCredentials([
            usernamePassword(
                credentialsId: 'aws-credentials',
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )
        ]) {
            sh """
                set -euxo pipefail
                ansible-playbook \\
                    -i ansible/inventories/\${ENV}/hosts.ini \\
                    ansible/playbooks/${config.playbook}
            """
        }
    }
}
