provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

data "azurerm_resource_group" "main" {
  name = var.resource
}

data "azurerm_ssh_public_key" "logstash" {
  name                = var.sshKey
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "networking" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.4.0.0/28"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.networking.name
  address_prefixes     = ["10.4.0.0/28"]
}

resource "azurerm_network_security_group" "http" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "http port"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ssh port"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.http.id

}

resource "azurerm_linux_virtual_machine_scale_set" "logstash" {
  name                = "${var.prefix}-vmss"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  zone_balance        = true
  zones               = [1, 2, 3]
  sku                 = var.machineSize
  instances           = var.capacity.minimum
  admin_username      = "azureuser"
  custom_data         = filebase64("${path.module}/custom-data.sh")

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.logstash.public_key
  }

  automatic_instance_repair {
    enabled      = true
    grace_period = "PT10M"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 30
  }

  extension {
    name                      = "healthRepairExtension"
    publisher                 = "Microsoft.ManagedServices"
    type                      = "ApplicationHealthLinux"
    type_handler_version      = "1.0"
    automatic_upgrade_enabled = true
    settings                  = <<settings
      {
        "protocol" : "http",
        "port" : 80,
        "requestPath" : "/"
      }
    settings
  }

  network_interface {
    name    = "${var.prefix}-NIC"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.subnet.id
    }
  }

  tags = {
    env      = var.environment
    service  = "website"
    createby = "brunojan"
    docker   = "yes"
    date     = formatdate("YYYY/MM/DD hh:mm:ss", timestamp())
    version  = var.website_version
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "${var.prefix}-${var.website_version}-scale-set"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.logstash.id

  profile {
    name = "default"

    capacity {
      default = var.capacity.minimum
      minimum = var.capacity.minimum
      maximum = var.capacity.maximum
    }

    dynamic "rule" {
      for_each = length(var.policies) > 0 ? var.policies : []
      content {
        metric_trigger {
          metric_name        = rule.value.metric
          metric_resource_id = azurerm_linux_virtual_machine_scale_set.logstash.id
          time_grain         = rule.value.grain
          statistic          = rule.value.statistic
          time_window        = rule.value.duration
          time_aggregation   = rule.value.statistic
          operator           = rule.value.operation
          threshold          = rule.value.threshold
          metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        }

        scale_action {
          direction = rule.value.action
          type      = "ChangeCount"
          value     = rule.value.count
          cooldown  = rule.value.cooldown
        }
      }
    }
  }

  dynamic "profile" {
    for_each = length(var.schedules) > 0 ? var.schedules : []

    content {
      name = profile.value.name

      capacity {
        default = profile.value.minimum
        minimum = profile.value.minimum
        maximum = profile.value.maximum
      }

      recurrence {
        timezone = "Taipei Standard Time"
        days     = profile.value.days
        hours    = profile.value.hours
        minutes  = profile.value.minutes
      }

    }
  }
}

