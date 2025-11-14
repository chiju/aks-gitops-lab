module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
}

module "vnet" {
  source = "./modules/vnet"

  name                = "${var.resource_group_name}-vnet"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
}

module "aks" {
  source = "./modules/aks"

  name                = "${var.resource_group_name}-aks"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  dns_prefix          = var.resource_group_name
  subnet_id           = module.vnet.aks_subnet_id
  kubernetes_version  = var.kubernetes_version
}