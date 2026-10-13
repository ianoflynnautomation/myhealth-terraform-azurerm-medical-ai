variable "vnet_name" {
  type        = string
  description = "Name of the virtual network."
  nullable    = false
}

variable "vnet_address_space" {
  type        = set(string)
  description = "Address spaces for the virtual network. Must contain the app and private-endpoint subnets."
  nullable    = false

  validation {
    condition     = length(var.vnet_address_space) > 0 && alltrue([for cidr in var.vnet_address_space : can(cidrhost(cidr, 0))])
    error_message = "vnet_address_space must contain at least one valid CIDR prefix."
  }
}

variable "app_subnet_name" {
  type        = string
  default     = "AppSubnet"
  description = "Name of the subnet that hosts pipeline compute. NAT Gateway is associated here."
  nullable    = false
}

variable "app_subnet_address_prefixes" {
  type        = list(string)
  default     = ["10.50.0.0/20"]
  description = "Address prefixes for the app/compute subnet. Must fall inside vnet_address_space."
  nullable    = false

  validation {
    condition     = length(var.app_subnet_address_prefixes) > 0 && alltrue([for cidr in var.app_subnet_address_prefixes : can(cidrhost(cidr, 0))])
    error_message = "app_subnet_address_prefixes must contain at least one valid CIDR prefix."
  }
}

variable "private_endpoint_subnet_name" {
  type        = string
  default     = "PrivateEndpointSubnet"
  description = "Name of the subnet that hosts private endpoints. Network policies are disabled on this subnet."
  nullable    = false
}

variable "private_endpoint_subnet_address_prefixes" {
  type        = list(string)
  default     = ["10.50.16.0/24"]
  description = "Address prefixes for the private-endpoint subnet. Override per environment (10.50.16.0/24 dev, 10.60.16.0/24 staging, 10.70.16.0/24 prod)."
  nullable    = false

  validation {
    condition     = length(var.private_endpoint_subnet_address_prefixes) > 0 && alltrue([for cidr in var.private_endpoint_subnet_address_prefixes : can(cidrhost(cidr, 0))])
    error_message = "private_endpoint_subnet_address_prefixes must contain at least one valid CIDR prefix."
  }
}

variable "nat_gateway_name" {
  type        = string
  default     = null
  description = "NAT Gateway name. When null, natgw-<environment>-<location_short_name> is used."
}

variable "nat_gateway_public_ip_name" {
  type        = string
  default     = null
  description = "Public IP name associated with the NAT Gateway. When null, pip-natgw-<environment>-<location_short_name> is used."
}

variable "nat_gateway_sku_name" {
  type        = string
  default     = "Standard"
  description = "NAT Gateway SKU. Standard is zonal. StandardV2 is zone-redundant and matches a zone-redundant public IP."
  nullable    = false

  validation {
    condition     = contains(["Standard", "StandardV2"], var.nat_gateway_sku_name)
    error_message = "nat_gateway_sku_name must be Standard or StandardV2."
  }
}

variable "nat_gateway_idle_timeout_in_minutes" {
  type        = number
  default     = 4
  description = "NAT Gateway idle timeout in minutes (Azure allows 4-120)."
  nullable    = false

  validation {
    condition     = var.nat_gateway_idle_timeout_in_minutes >= 4 && var.nat_gateway_idle_timeout_in_minutes <= 120
    error_message = "nat_gateway_idle_timeout_in_minutes must be between 4 and 120."
  }
}
