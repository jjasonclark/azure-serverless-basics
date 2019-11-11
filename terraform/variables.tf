variable "project_name" {
  description = "Prefix name of created Azure resources"
  type        = string
  default     = "azure-serverless-basics"
}

variable "stage" {
  description = "Prefix environment name of created Azure resources"
  type        = string
  default     = "dev"
}

variable "storage_account_name" {
  description = "Name of storage account"
  type        = string
  default     = "azureserverlessbasicsdev"
}
