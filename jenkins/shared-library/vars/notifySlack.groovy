def call(Map config) {
    def color = config.status == 'success' ? 'good' : 'danger'
    def statusText = config.status == 'success' ? '성공 ✅' : '실패 ❌'
    def buildUrl = env.BUILD_URL ?: 'N/A'

    def payload = """{
    "attachments": [{
        "color": "${color}",
        "title": "배포 ${statusText}",
        "fields": [
            {"title": "서비스", "value": "${config.service}", "short": true},
            {"title": "환경",   "value": "${config.env}",     "short": true},
            {"title": "이미지 태그", "value": "${config.tag}", "short": true},
            {"title": "빌드 URL", "value": "${buildUrl}", "short": false}
        ]
    }]
}"""

    withCredentials([string(credentialsId: 'SLACK_WEBHOOK_URL', variable: 'SLACK_URL')]) {
        writeFile file: 'slack_payload.json', text: payload
        sh "curl -s -X POST \"\${SLACK_URL}\" -H 'Content-Type: application/json' --data-binary @slack_payload.json"
        sh "rm -f slack_payload.json"
    }
}
