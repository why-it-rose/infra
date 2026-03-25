def getBuildUrl(build) {
    try {
        return build.absoluteUrl
    } catch (e) {
        return "N/A (Jenkins URL 미설정)"
    }
}

def call(Map config) {
    def color = config.status == 'success' ? 'good' : 'danger'
    def statusText = config.status == 'success' ? '성공 ✅' : '실패 ❌'

    def payload = """{
    "attachments": [{
        "color": "${color}",
        "title": "배포 ${statusText}",
        "fields": [
            {"title": "서비스", "value": "${config.service}", "short": true},
            {"title": "환경",   "value": "${config.env}",     "short": true},
            {"title": "이미지 태그", "value": "${config.tag}", "short": true},
            {"title": "빌드 URL", "value": "${getBuildUrl(currentBuild)}", "short": false}
        ]
    }]
}"""

    withCredentials([string(credentialsId: 'SLACK_WEBHOOK_URL', variable: 'SLACK_URL')]) {
        writeFile file: 'slack_payload.json', text: payload
        sh "curl -s -X POST \"\${SLACK_URL}\" -H 'Content-Type: application/json' --data-binary @slack_payload.json"
        sh "rm -f slack_payload.json"
    }
}
