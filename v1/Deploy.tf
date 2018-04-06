######################################################################
# Access to Azure
######################################################################
# Configure the Microsoft Azure Provider with Azure provider variable defined in AzureDFProvider.tf
provider "azurerm" {
  subscription_id = "${var.AzureSubscriptionID}"
  client_id       = "${var.AzureClientID}"
  client_secret   = "${var.AzureClientSecret}"
  tenant_id       = "${var.AzureTenantID}"
}

# Create Ressource Group
resource "azurerm_resource_group" "RSG-Lambda" {
  name     = "${var.RSGName}"
  location = "${var.AzureRegion}"
}

######################################################################
# Creation Cosmos DB
######################################################################

# Create Comsos DB
resource "azurerm_cosmosdb_account" "CosmosDB-Lambda" {
  name                = "${var.CosmosName}"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RSG-Lambda.name}"
  offer_type          = "Standard"

  consistency_policy {
    consistency_level = "BoundedStaleness"
  }

  failover_policy {
    location = "${var.AzureRegion}"
    priority = 0
  }
}

######################################################################
# Creation VM Environement 
######################################################################

# Create Virtual Network
resource "azurerm_virtual_network" "VNet-LambdaVM" {
  name                = "${var.VnetName}"
  address_space       = "${var.AddressSpace}"
  location            = "${var.AzureRegion}"
  resource_group_name = "${var.RSGName}"
}

# Create Subnet
resource "azurerm_subnet" "Subnet-LambdaVM" {
  name                 = "${var.SubnetName}"
  resource_group_name  = "${azurerm_resource_group.RSG-Lambda.name}"
  virtual_network_name = "${azurerm_virtual_network.VNet-LambdaVM.name}"
  address_prefix       = "${var.AddressPrefix}"
}

# Create public IPs
resource "azurerm_public_ip" "PublicIP-LambdaVM" {
  name                         = "${var.PublicIPName}"
  location                     = "${var.AzureRegion}"
  resource_group_name          = "${azurerm_resource_group.RSG-Lambda.name}"
  public_ip_address_allocation = "dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "NSG-LambdaVM" {
  name                = "${var.NSGName}"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RSG-Lambda.name}"

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create Network Interface
resource "azurerm_network_interface" "NetworkInterface-LambdaVM" {
  name                      = "${var.NetworkInterfaceName}"
  location                  = "${var.AzureRegion}"
  resource_group_name       = "${azurerm_resource_group.RSG-Lambda.name}"
  network_security_group_id = "${azurerm_network_security_group.NSG-LambdaVM.id}"

  ip_configuration {
    name                          = "${var.NicName}"
    subnet_id                     = "${azurerm_subnet.Subnet-LambdaVM.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.PublicIP-LambdaVM.id}"
  }
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "StorageAccount-LambdaVM" {
  name                     = "${var.StorageAccountName}"
  resource_group_name      = "${azurerm_resource_group.RSG-Lambda.name}"
  location                 = "${var.AzureRegion}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_virtual_machine" "VM-LambdaVM" {
  name                  = "${var.VMName}"
  location              = "${var.AzureRegion}"
  resource_group_name   = "${azurerm_resource_group.RSG-Lambda.name}"
  network_interface_ids = ["${azurerm_network_interface.NetworkInterface-LambdaVM.id}"]
  vm_size               = "Standard_D1_v2"

  storage_os_disk {
    name              = "${var.VMOSDiskName}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${var.VMName}"
    admin_username = "${var.VMAdminUsername}"
    admin_password = "${var.VMAdminPassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.StorageAccount-LambdaVM.primary_blob_endpoint}"
  }
}

######################################################################
# Creation HDInsight Spark
######################################################################

resource "azurerm_template_deployment" "Template-LambdaSpark" {
  name                = "terraclustersparktemplate"
  resource_group_name = "${azurerm_resource_group.RSG-Lambda.name}"

  template_body = <<DEPLOY
{
    "$schema":"https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion":"1.0.0.0",
    "parameters":{
        "clusterName":{
            "type":"string",
            "metadata":{
                "description":"The name of the HDInsight cluster to create."
            }
        },
        "clusterLoginUserName":{
            "type":"string",
            "defaultValue":"admin",
            "metadata":{
                "description":"These credentials can be used to submit jobs to the cluster and to log into cluster dashboards."
            }
        },
        "clusterLoginPassword":{
            "type":"securestring",
            "metadata":{
                "description":"The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter."
            }
        },
        "sshUserName":{
            "type":"string",
            "defaultValue":"sshuser",
            "metadata":{
                "description":"These credentials can be used to remotely access the cluster."
            }
        },
        "sshPassword":{
            "type":"securestring",
            "metadata":{
                "description":"The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter."
            }
        }
    },
    "variables":{
        "defaultStorageAccount":{
            "name":"${var.SparkClusterStorageAccountName}",
            "type":"Standard_LRS"
        }
    },
    "resources":[
        {
            "type":"Microsoft.Storage/storageAccounts",
            "name":"[variables('defaultStorageAccount').name]",
            "location":"[resourceGroup().location]",
            "apiVersion":"2016-01-01",
            "sku":{
                "name":"[variables('defaultStorageAccount').type]"
            },
            "kind":"Storage",
            "properties":{}
        },
        {
            "type":"Microsoft.HDInsight/clusters",
            "name":"[parameters('clusterName')]",
            "location":"[resourceGroup().location]",
            "apiVersion":"2015-03-01-preview",
            "dependsOn":[
                "[concat('Microsoft.Storage/storageAccounts/',variables('defaultStorageAccount').name)]"
            ],
            "tags":{},
            "properties":{
                "clusterVersion":"3.6",
                "osType":"Linux",
                "tier":"Standard",
                "clusterDefinition":{
                    "kind":"spark",
                    "configurations":{
                        "gateway":{
                            "restAuthCredential.isEnabled":true,
                            "restAuthCredential.username":"[parameters('clusterLoginUserName')]",
                            "restAuthCredential.password":"[parameters('clusterLoginPassword')]"
                        }
                    }
                },
                "storageProfile":{
                    "storageaccounts":[
                        {
                            "name":"[replace(replace(reference(resourceId('Microsoft.Storage/storageAccounts', variables('defaultStorageAccount').name), '2016-01-01').primaryEndpoints.blob,'https://',''),'/','')]",
                            "isDefault":true,
                            "container":"[parameters('clusterName')]",
                            "key":"[listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('defaultStorageAccount').name), '2016-01-01').keys[0].value]"
                        }
                    ]
                },
                "computeProfile":{
                    "roles":[
                        {
                            "name": "headnode",
                            "targetInstanceCount": "2",
                            "hardwareProfile": {
                                "vmSize": "Standard_D3_v2"
                            },
                            "osProfile":{
                                "linuxOperatingSystemProfile":{
                                    "username":"[parameters('sshUserName')]",
                                    "password":"[parameters('sshPassword')]"
                                }
                            },
                            "virtualNetworkProfile": null,
                            "scriptActions": []
                        },
                        {
                            "name": "workernode",
                            "targetInstanceCount": "2",
                            "hardwareProfile": {
                                "vmSize": "Standard_D3_v2"
                            },
                            "osProfile":{
                                "linuxOperatingSystemProfile":{
                                    "username":"[parameters('sshUserName')]",
                                    "password":"[parameters('sshPassword')]"
                                }
                            },
                            "virtualNetworkProfile": null,
                            "scriptActions": []
                        }
                    ]
                }
            }
        }
    ],
    "outputs":{
        "storage":{
        "type": "object",
        "value": "[reference(resourceId('Microsoft.Storage/storageAccounts', variables('defaultStorageAccount').name))]"
        },
        "cluster":{
            "type":"object",
            "value":"[reference(resourceId('Microsoft.HDInsight/clusters',parameters('clusterName')))]"
        }
    }
}
DEPLOY

  parameters {
    "clusterName" = "${var.SparkClusterName}"
    "clusterLoginUserName" = "${var.SparkClusterLogin}"
    "clusterLoginPassword" = "${var.SparkClusterPassword}"
    "sshUserName" = "${var.SparkClusterSSHUsername}"
    "sshPassword" = "${var.SparkClusterSSHPassword}"
  }
  
  deployment_mode = "Incremental"
}
