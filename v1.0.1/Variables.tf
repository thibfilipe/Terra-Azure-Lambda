#############################################################
# Variables 
######################################################################
######################################################################
######################################################################

# Variable to define the Azure Region
variable "AzureRegion" {
  type    = "string"
  default = "westeurope"
}

# Variable to define the Resource Group Name
variable "RSGName" {
  type    = "string"
  default = "RSG-terra_Lambda"
}

######################################################################
# Creation Cosmos DB
######################################################################

# Variable to define the Cosmos DB Name
variable "CosmosName" {
  type    = "string"
  default = "terraformcomsos"
}

######################################################################
# Creation VM Environement 
######################################################################

# Variable to define the Vistual Network Name
variable "VnetName" {
  type    = "string"
  default = "terra_vnet"
}

variable "AddressSpace" {
  type    = "list"
  default = ["10.0.0.0/16"]
}

# Variable to define VM Subnet 
variable "SubnetName" {
  type    = "string"
  default = "terra_subnet"
}

variable "AddressPrefix" {
  type    = "string"
  default = "10.0.1.0/24"
}

# Variable to define HDI Subnet 
variable "HDISubnetName" {
  type    = "string"
  default = "terra_hdisubnet"
}

variable "HDIAddressPrefix" {
  type    = "string"
  default = "10.0.2.0/24"
}

# Variable to define the Public IP Name
variable "PublicIPName" {
  type    = "string"
  default = "terra_publicip"
}

# Variable to define the NSG Name
variable "NSGName" {
  type    = "string"
  default = "terra_nsg"
}

# Variable to define the Network Interface 
variable "NetworkInterfaceName" {
  type    = "string"
  default = "terra_networkinterface"
}

variable "NicName" {
  type    = "string"
  default = "terra_nic"
}

# Variable to define the VM Storage Account Name
variable "StorageAccountName" {
  type    = "string"
  default = "terraformlambdavmstorage"
}

# Variable to define the VM Name
variable "VMName" {
  type    = "string"
  default = "terraVM"
}

# Variable to define the VM OS Disk Name
variable "VMOSDiskName" {
  type    = "string"
  default = "terraVMOsDisk"
}

# Variable to define OS Admin Username
variable "VMAdminUsername" {
  type    = "string"
  default = "userssh"
}

# Variable to define OS Admin Password
variable "VMAdminPassword" {
  type    = "string"
  default = "Password1234!"
}

######################################################################
# Creation HDInsight Spark
######################################################################

# Variable to define Spark Storage Account Name
variable "SparkClusterStorageAccountName" {
  type    = "string"
  default = "terraclustersparkstorage"
}


# Variable to define Cluster Name
variable "SparkClusterName" {
  type    = "string"
  default = "terraclusterspark"
}

# Variable to define Cluster Login
variable "SparkClusterLogin" {
  type    = "string"
  default = "terraloginspark"
}

# Variable to define Cluster Password
variable "SparkClusterPassword" {
  type    = "string"
  default = "Password123!"
}

# Variable to define SSH Username
variable "SparkClusterSSHUsername" {
  type    = "string"
  default = "userssh"
}

# Variable to define SSH Password
variable "SparkClusterSSHPassword" {
  type    = "string"
  default = "Password123!"
}