locals {
  tags = {
    project = var.project_name
  }
  cSharpPath = "../src/bin/Release/net461"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-${var.stage}"
  location = "East US"
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_container" "deployments" {
  name                  = "deployments"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

data "archive_file" "c-sharp" {
  type        = "zip"
  source_dir  = local.cSharpPath
  output_path = "../src/bin/Release/c-sharp.zip"
}

resource "azurerm_storage_blob" "c-sharp" {
  name                   = "c-sharp.zip"
  storage_account_name   = azurerm_storage_account.main.name
  storage_container_name = azurerm_storage_container.deployments.name
  type                   = "block"
  source                 = data.archive_file.c-sharp.output_path
}

data "azurerm_storage_account_sas" "main" {
  connection_string = azurerm_storage_account.main.primary_connection_string
  start             = "2019-11-08"
  expiry            = "2020-12-31"
  resource_types {
    object    = true
    container = false
    service   = false
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

resource "azurerm_app_service_plan" "main" {
  name                = "${var.project_name}-${var.stage}-functions"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kind                = "FunctionApp"
  tags                = local.tags
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "main" {
  name                      = "${var.project_name}-${var.stage}-c-sharp"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  app_service_plan_id       = azurerm_app_service_plan.main.id
  storage_connection_string = azurerm_storage_account.main.primary_connection_string
  tags                      = local.tags
  version                   = "~1"

  app_settings = {
    https_only               = true
    FUNCTIONS_WORKER_RUNTIME = "dotnet"
    FUNCTION_APP_EDIT_MODE   = "readonly"
    HASH                     = data.archive_file.c-sharp.output_base64sha256
    WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.main.name}.blob.core.windows.net/${azurerm_storage_container.deployments.name}/${azurerm_storage_blob.c-sharp.name}${data.azurerm_storage_account_sas.main.sas}"
  }
}
