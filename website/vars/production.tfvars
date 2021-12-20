resource        = "dotnetconf2021"
subscription_id = ""
prefix          = "Study4-Website"
machineSize     = "Standard_B1ms"
sshKey          = "study4-website-sshkey"
environment     = "production"
website_version = "1.0.0"
capacity = {
  minimum = 2
  maximum = 10
}
policies = [
  {
    metric    = "Percentage CPU"
    statistic = "Average"
    grain     = "PT1M"
    duration  = "PT1M"
    operation = "GreaterThan"
    threshold = 65
    action    = "Increase"
    count     = 2
    cooldown  = "PT10M"
  },
  {
    metric    = "Percentage CPU"
    statistic = "Average"
    grain     = "PT1M"
    duration  = "PT1M"
    operation = "LessThan"
    threshold = 40
    action    = "Decrease"
    count     = 1
    cooldown  = "PT10M"
  }
]
schedules = []
