
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        string(
            name: 'RELEASE_VERSION',
            defaultValue: '1.0.0',
            description: 'Enter release version'
        )

        choice(
            name: 'DEPLOY_ENV',
            choices: ['development', 'staging', 'production'],
            description: 'Select deployment environment'
        )

        choice(
            name: 'RELEASE_ACTION',
            choices: ['package', 'cancel'],
            description: 'Select release action'
        )
    }

    stages {

        stage('Inspect Workspace') {
            steps {
                echo "Job Name: ${env.JOB_NAME}"
                echo "Build Number: ${env.BUILD_NUMBER}"
                echo "Build URL: ${env.BUILD_URL}"
                echo "Release Version: ${params.RELEASE_VERSION}"
                echo "Environment: ${params.DEPLOY_ENV}"
            }
        }

        stage('Validate Repository') {
            steps {
                echo "Checking repository files"

                sh 'ls -la'

                sh 'sh scripts/validate-release.sh'
            }
        }

        stage('Validate Release Version') {
            steps {
                script {
                    if (!params.RELEASE_VERSION?.trim()) {
                        error("Release version cannot be blank")
                    }

                    if (!(params.RELEASE_VERSION ==~ /^\d+\.\d+\.\d+$/)) {
                        error("Invalid version. Use format 1.0.0")
                    }

                    echo "Valid Release Version: ${params.RELEASE_VERSION}"
                }
            }
        }

        stage('Prepare Release Package') {
            steps {
                sh '''
                    mkdir -p release/app
                    mkdir -p release/config
                    mkdir -p release/docs

                    cp app/index.html release/app/
                    cp config/release-policy.txt release/config/
                    cp docs/release-notes.md release/docs/

                    echo "Release package prepared"
                '''
            }
        }

        stage('Generate Release Manifest') {
            steps {
                sh """
                    cat > release/manifest.txt <<EOF
Release Version: ${params.RELEASE_VERSION}
Environment: ${params.DEPLOY_ENV}
Jenkins Job: ${env.JOB_NAME}
Build Number: ${env.BUILD_NUMBER}
Build URL: ${env.BUILD_URL}
EOF
                """

                echo "Release manifest generated"
            }
        }

        stage('Package Verification') {
            steps {
                sh '''
                    set -eu

                    test -s release/app/index.html
                    test -s release/config/release-policy.txt
                    test -s release/docs/release-notes.md
                    test -s release/manifest.txt

                    echo "Verifying manifest version"

                    grep -F "Release Version: ${RELEASE_VERSION}" release/manifest.txt

                    echo "Package verification successful"
                '''
            }
        }

        stage('Manual Release Approval') {
            steps {
                script {
                    input(
                        message: "Approve Release ${params.RELEASE_VERSION} for ${params.DEPLOY_ENV}?",
                        ok: 'Proceed'
                    )

                    env.APPROVAL_GRANTED = 'true'

                    echo "Manual approval granted"
                }
            }
        }

        stage('Release Decision') {
            steps {
                script {
                    if (params.RELEASE_ACTION == 'cancel') {
                        env.APPROVAL_GRANTED = 'false'
                        echo "Release cancelled. Package will not be archived."
                    } else {
                        echo "Package release selected"
                    }
                }
            }
        }

        stage('Archive Release Package') {
            when {
                expression {
                    params.RELEASE_ACTION == 'package' &&
                    env.APPROVAL_GRANTED == 'true'
                }
            }

            steps {
                archiveArtifacts(
                    artifacts: 'release/**',
                    fingerprint: true
                )

                echo "Release package archived successfully"
            }
        }
    }

    post {
        success {
            echo "SUCCESS: Pipeline completed successfully"
        }

        failure {
            echo "FAILURE: Pipeline execution failed"
        }

        aborted {
            echo "ABORTED: Manual approval was rejected or the build was stopped"
        }

        always {
            echo "Pipeline execution finished"
        }
    }
}
