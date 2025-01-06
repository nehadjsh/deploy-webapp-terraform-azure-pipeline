# Terraform Configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"

  # Backend configuration for remote state storage
  backend "azurerm" {
    resource_group_name  = "Backend"  # Replace with pipeline variable if dynamic
    storage_account_name = "storage4backend0"
    container_name       = "tfcontainer"
    key                  = "terraform.tfstate"
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# App Service Plan
resource "azurerm_service_plan" "service_plan" {
  name                = "${var.app_name}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = var.plan_sku
}

# Linux Web App
resource "azurerm_linux_web_app" "web_app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.service_plan.id

  site_config {
    always_on = true
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    DOCKER_CUSTOM_IMAGE_NAME            = var.docker_image
    DOCKER_ENABLE_CI                    = "false"
  }

  https_only = true

  identity {
    type = "SystemAssigned"
  }
}

# Output Web App URL
output "web_app_url" {
  value = "https://${azurerm_linux_web_app.web_app.default_hostname}"
}

# Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "app_name" {
  description = "Name of the Web App"
  type        = string
}

variable "docker_image" {
  description = "Docker image from Docker Hub"
  type        = string
}

variable "plan_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "P2v2" 
}
