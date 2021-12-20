variable "subscription_id" {
  type        = string
  description = "azure subscription"
}
variable "resource" {
  type        = string
  description = "website will be create in the resource group "
}

variable "prefix" {
  type        = string
  description = "website resource naming prefix"
}

variable "machineSize" {
  type        = string
  description = "website vm size"
}

variable "sshKey" {
  type        = string
  description = "website azureuser login ssh public key"
}

variable "environment" {
  type        = string
  description = "website deployment for environment"
}

variable "website_version" {
  type        = string
  description = "website deployment version"
}

variable "capacity" {
  type = object({
    minimum = number
    maximum = number
  })
}

variable "policies" {
  type = set(object({
    metric    = string
    statistic = string
    grain     = string
    duration  = string
    operation = string
    threshold = number
    action    = string
    count     = string
    cooldown  = string
  }))
  description = "website autoscaling policies"
}

variable "schedules" {
  type = set(object({
    name    = string
    minimum = number
    maximum = number
    days    = list(string)
    hours   = list(number)
    minutes = list(number)
  }))
  description = "website schedule scaling policies"
}
