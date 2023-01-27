variable "username" {
  type        = string
  description = "Your linux session username"
}

variable "private_key_path" {
  type        = string
  description = "Path to your private key (ex: /home/your-user/.ssh/id_rsa)"
}

variable "public_key_path" {
  type        = string
  description = "Path to your public key (ex: /home/your-user/.ssh/id_rsa.pub)"
}
