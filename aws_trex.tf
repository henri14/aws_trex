terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
  shared_credentials_files = [var.aws_shared_credentials_file]
}

data "aws_availability_zones" "available" {}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.14.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.14.1.0/24"
  map_public_ip_on_launch = true
  # Pin to first AZ
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

# Create a subnet for traffic generation interfaces
resource "aws_subnet" "trafgen" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.14.2.0/24"
  map_public_ip_on_launch = false
  # Pin to first AZ
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "trex-admin-sg"
  description = "Used for TRex instances"
  vpc_id      = aws_vpc.default.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_inbound_cidr.inbound_cidr]
  }

  # HTTPS access from the VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.14.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "trafgen" {
  name        = "trafgen-sg"
  description = "Used for TRex traffic"
  vpc_id      = aws_vpc.default.id

  # allow anything in from our SG
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }

  # allow anything in from our specified CIDR
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allowed_inbound_cidr.inbound_cidr]
  }

  # allow anything out
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair" "auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_network_interface" "trex-admin-nic-0" {
  subnet_id       = aws_subnet.default.id
  security_groups = [aws_security_group.default.id]
}

resource "aws_network_interface" "trex-trafgen-nic-1" {
  subnet_id       = aws_subnet.trafgen.id
  security_groups = [aws_security_group.trafgen.id]
}

resource "aws_network_interface" "trex-trafgen-nic-2" {
  subnet_id       = aws_subnet.trafgen.id
  security_groups = [aws_security_group.trafgen.id]
}

resource "aws_eip" "trex-loadgen-eip-0" {
  domain = "vpc"
}

resource "aws_eip_association" "trex-loadgen-eip-assoc" {
  allocation_id = aws_eip.trex-loadgen-eip-0.id
  network_interface_id = aws_network_interface.trex-admin-nic-0.id
}


resource "aws_instance" "trex-loadgen" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    type = "ssh"
    # The default username for our AMI
    user = "ec2-user"
    host = aws_eip.trex-loadgen-eip-0.public_ip
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "c5n.2xlarge"

  # Lookup the correct AMI based on the region
  # we specified
  ami = var.aws_amis[var.aws_region]

  # The name of our SSH keypair we created above.
  key_name = aws_key_pair.auth.id

  # Pin to first AZ
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  network_interface {
    device_index         = 0
    network_interface_id = "${aws_network_interface.trex-admin-nic-0.id}"

    #delete_on_termination = true
  }

  network_interface {
    device_index         = 1
    network_interface_id = "${aws_network_interface.trex-trafgen-nic-1.id}"

    #delete_on_termination = true
  }

  network_interface {
    device_index         = 2
    network_interface_id = "${aws_network_interface.trex-trafgen-nic-2.id}"

    #delete_on_termination = true
  }

  user_data = templatefile("trex_cloud_init.yaml.tpl", 
                   {trex_bundle_url = var.trex_bundle_url,
                    trex_dpdk_setup_conf_b64 = filebase64(var.dpdk_setup_file),
                   })
  
}

output "trex-loadgen-public-ip" { 
    value = aws_eip.trex-loadgen-eip-0
}

resource "aws_network_interface" "trex-samplicator-nic-0" {
  subnet_id       = aws_subnet.trafgen.id
  security_groups = [aws_security_group.trafgen.id]
}

resource "aws_eip" "trex-samplicator-eip-0" {
  domain = "vpc"
}

resource "aws_eip_association" "trex-samplicator-eip-assoc" {
  allocation_id = aws_eip.trex-samplicator-eip-0.id
  network_interface_id = aws_network_interface.trex-samplicator-nic-0.id
}

resource "aws_instance" "trex-samplicator" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    type = "ssh"
    # The default username for our AMI
    user = "ec2-user"
    host = aws_eip.trex-samplicator-eip-0.public_ip
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = var.aws_amis[var.aws_region]

  # The name of our SSH keypair we created above.
  key_name = aws_key_pair.auth.id

  # Pin to first AZ
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  network_interface {
    device_index         = 0
    network_interface_id = "${aws_network_interface.trex-samplicator-nic-0.id}"

    #delete_on_termination = true
  }

  user_data = templatefile("samplicator_cloud_init.yaml.tpl", 
                   {samplicator_bundle_url = var.samplicator_bundle_url,
                    samplicator_bundle_dir = var.samplicator_bundle_dir,
                    samplicator_conf_b64 = filebase64(var.samplicator_conf_file),
                    samplicator_service_b64 = filebase64(var.samplicator_service_file),
                   })
}

output "trex-samplicator-public-ip" { 
    value = aws_eip.trex-samplicator-eip-0
}
