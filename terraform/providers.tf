provider "azurerm" {
  version = "=1.35.0"
}

provider "archive" {
  version = "~>1.3"
}

terraform {
  required_version = ">= 0.12.0"
}
