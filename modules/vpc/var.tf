# Input variable definitions

variable "db_name" {
  description = "Name of the Database."
  type        = string
  default = "wordpressdb"
}

variable "db_username" {
  description = "Master user name"
  type        = string
  default = "wordpress"
}

variable "db_password" {
  description = "Master password"
  type        = string
  default = "password"
}
