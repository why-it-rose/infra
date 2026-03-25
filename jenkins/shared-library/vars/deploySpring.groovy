def call(Map config) {
    def env = config.env
    def imageTag = config.imageTag
    def hostCredId = env == 'prod' ? 'EC2_HOST_PROD' : 'EC2_HOST_DEV'
    def composeFile = "~/wir/infra/docker-compose/docker-compose.${env}.yml"

    withCredentials([string(credentialsId: hostCredId, variable: 'EC2_HOST')]) {
        sshagent(credentials: ['EC2_SSH_KEY']) {
            sh """
                ssh -o StrictHostKeyChecking=no ubuntu@\${EC2_HOST} \
                    'cd ~/wir/infra && git pull && \
                    BACKEND_IMAGE_TAG=${imageTag} docker compose -f ${composeFile} pull backend && \
                    BACKEND_IMAGE_TAG=${imageTag} docker compose -f ${composeFile} up -d backend'
            """

            // 헬스체크: 최대 30초 (5초 간격, 6회)
            def healthy = false
            for (int i = 0; i < 6; i++) {
                sleep(5)
                def code = sh(
                    script: "ssh -o StrictHostKeyChecking=no ubuntu@\${EC2_HOST} 'curl -s -o /dev/null -w \"%{http_code}\" http://localhost:8080/actuator/health'",
                    returnStdout: true
                ).trim()
                if (code == '200') {
                    healthy = true
                    break
                }
            }
            if (!healthy) {
                error "[deploySpring] Health check failed (env: ${env}, tag: ${imageTag})"
            }
        }
    }
}
