#!/usr/bin/env groovy

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'
  govuk.buildProject(overrideTestTask: {
    stage("Run tests") {
      govuk.withStatsdTiming("test_task") {
        sh("bundle exec rspec -f d")
      }
    }
  })
}
