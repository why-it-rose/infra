def call(Map config) {
    def env = config.env
    def imageTag = config.imageTag
    def batchImageTag = config.batchImageTag
    def hostCredId = env == 'prod' ? 'EC2_HOST_PROD' : 'EC2_HOST_DEV'
    def infraBranch = env == 'prod' ? 'main' : 'develop'
    def composeDir = "~/wir/infra/docker-compose"
    def composeFile = "${composeDir}/docker-compose.${env}.yml"
    def envFile = "${composeDir}/.env.${env}"

    withCredentials([string(credentialsId: hostCredId, variable: 'EC2_HOST')]) {
        sshagent(credentials: ['EC2_SSH_KEY']) {
            sh """
                ssh -o StrictHostKeyChecking=no ubuntu@\${EC2_HOST} \
                    'cd ~/wir/infra && git fetch origin && git reset --hard origin/${infraBranch} && \
                    BACKEND_IMAGE_TAG=${imageTag} BATCH_IMAGE_TAG=${batchImageTag} docker compose -f ${composeFile} --env-file ${envFile} pull backend batch && \
                    BACKEND_IMAGE_TAG=${imageTag} BATCH_IMAGE_TAG=${batchImageTag} docker compose -f ${composeFile} --env-file ${envFile} up -d backend batch'
            """

            // 헬스체크: 최대 90초 (10초 간격, 9회)
            def healthy = false
            for (int i = 0; i < 9; i++) {
                sleep(10)
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
