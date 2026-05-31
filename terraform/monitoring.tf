resource "datadog_monitor" "redmine_http_check" {
  name = "Project 77 Redmine HTTP check"
  type = "service check"

  query = "\"http.can_connect\".over(\"instance:redmine-local\").by(\"host\").last(2).count_by_status()"

  message = "Redmine HTTP check failed on one of the project-77 web servers."

  monitor_thresholds {
    critical = 1
    warning  = 1
  }

  notify_no_data    = false
  renotify_interval = 0

  tags = [
    "project:devops-for-developers-project-77",
    "app:redmine",
    "managed-by:terraform"
  ]
}
