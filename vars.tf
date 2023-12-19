variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/terraform.pub
DESCRIPTION
}

variable "key_name" {
  description = "Name of ssh key pair in EC2"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "ap-southeast-2"
}

# RedHat Enterprise Linux 9 (x64)
variable "aws_amis" {
  default = {
    ap-southeast-2 = "ami-0ade3fd7d152f84df"
  }
}

variable "aws_shared_credentials_file" {
    description = "File containing access key and secret for AWS provider"
}

variable "allowed_inbound_cidr" {
  description = "Network range allowed to access instances over SSH or HTTPS"
  default = {
    inbound_cidr = "1.1.1.1/32"
  }
}

variable "trex_bundle_url" {
  description = "URL for trex bundle"
  default = "https://trex-tgn.cisco.com/trex/release/latest"
}

variable "dpdk_setup_file" {
  description = "Script to download, compile and install igb_uio driver"
  default = "artefacts/dpdk_setup.sh"
}

variable "samplicator_conf_file" {
  description = "Configuration file for samplicator application"
  default = "artefacts/samplicator.conf"
}

variable "samplicator_service_file" {
  description = "Systemd service definition for samplicator"
  default = "artefacts/samplicator.service"
}

variable "samplicator_bundle_url" {
  description = "URL to download samplicator application"
  default = "https://github.com/sleinen/samplicator/releases/download/v1.3.6/samplicator-1.3.6.tar.gz"
}

variable "samplicator_bundle_dir" {
  description = "Directory name for samplicator within the installation bundle"
  default = "samplicator-1.3.6"
}
