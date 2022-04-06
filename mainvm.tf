resource "azurerm_resource_group" "myvm2" {
  name     = var.myrgname2
  location = var.myloc2
}

resource "azurerm_virtual_network" "myvnet2" {
  name                = var.myvnet2
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myvm2.location
  resource_group_name = azurerm_resource_group.myvm2.name
}

resource "azurerm_subnet" "mysub2" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.myvm2.name
  virtual_network_name = azurerm_virtual_network.myvnet2.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "mypip" {
  name                = var.mypip
  resource_group_name = azurerm_resource_group.myvm2.name
  location            = azurerm_resource_group.myvm2.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.nsg
  location            = azurerm_resource_group.myvm2.location
  resource_group_name = azurerm_resource_group.myvm2.name

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
resource "azurerm_network_interface" "mynic2" {
  name                = var.mynic2
  location            = azurerm_resource_group.myvm2.location
  resource_group_name = azurerm_resource_group.myvm2.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.mysub2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mypip.id
  }
}
resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.mynic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "myvm22" {
  name                = var.myvm22
  resource_group_name = azurerm_resource_group.myvm2.name
  location            = azurerm_resource_group.myvm2.location
  size                = "Standard_DS1"
  admin_username      = "adminuser"
  admin_password      = "myvm@1234567"
  network_interface_ids = [
    azurerm_network_interface.mynic2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}