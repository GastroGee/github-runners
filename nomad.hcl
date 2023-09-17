job "github_runner" {
  datacenters     = ["dc1"]
  type = "system"
  task "runner" {
    config {
      image = "ephemeral_image_name:tag"
      privileged = true
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock",
        "/home/github-runner:/home/github-runner",
      ]
    }

    driver = "docker"

    env {
      LABELS = "${attr.unique.hostname}"
    }

    restart {
      attempts = 10
      delay    = "15s"
      interval = "1m"
      mode     = "delay"
    }

    template {
      change_mode = "noop"
      data = <<EOH
{_ with secret "github/token/ephemeral-github-runners" _}{_ .Data.token _}{_ end _}
EOH
      left_delimiter  = "{_"
      right_delimiter = "_}"
      destination = "local/access-token.txt"
    }
  }

  vault {
    policies = [
        "github-token-generator",
        "secrets-services-ephemeral-github-runner"
    ]
  }
}
