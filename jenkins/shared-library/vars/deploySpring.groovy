def call(Map config) {
    def env = config.env
    def imageTag = config.imageTag
    def batchImageTag = config.batchImageTag
    def hostCredId = env == 'prod' ? 'EC2_HOST_PROD' : 'EC2_HOST_DEV'
    def infraBranch = env == 'prod' ? 'main' : 'develop'
    def composeFile = "~/wir/infra/docker-compose/docker-compose.${env}.yml"

    withCredentials([string(credentialsId: hostCredId, variable: 'EC2_HOST')]) {
        sshagent(credentials: ['EC2_SSH_KEY']) {
            def deployServices = (batchImageTag && batchImageTag != 'null') ? 'backend batch' : 'backend'
            def batchEnv = (batchImageTag && batchImageTag != 'null') ? "BATCH_IMAGE_TAG=${batchImageTag} " : ''

            sh """
                ssh -o StrictHostKeyChecking=no ubuntu@\${EC2_HOST} \
                    'cd ~/wir/infra && git fetch origin && git reset --hard origin/${infraBranch} && \
                    BACKEND_IMAGE_TAG=${imageTag} ${batchEnv}docker compose -f ${composeFile} pull ${deployServices} && \
                    BACKEND_IMAGE_TAG=${imageTag} ${batchEnv}docker compose -f ${composeFile} up -d ${deployServices}'
            """

            // 헬스체크: 최대 30초 (5초 간격, 6회)
            def healthy = false
            for (int i = 0; i < 6; i++) {
                sleep(5)
                def code = sh(
                    script: "ssh -o StrictHostKeyChecking=no ubuntu@\${EC2_HOST} 'curl -s -o /dev/null -w \"%{http_code}\" http://localhost:8080/actuator/health' || echo 000",
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
