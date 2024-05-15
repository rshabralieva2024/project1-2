resource "aws_security_group" "db-sg" {
  vpc_id = aws_vpc.main.id
  name   = "db-sg"
  description = "Allow access to our DB from anywhere"

  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 63306
    # security_groups = [aws_security_group.allow_tls.id]  # Replace <instance> with the actual identifier of your instance's security group
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# RDS cluster
resource "aws_rds_cluster" "rds-cluster" {
  cluster_identifier        = "rds-cluster"
  availability_zones = ["us-east-2a", "us-east-2b"] #Update the AZs accordingly
  engine                    = "aurora-mysql"
  engine_version            = "5.7.mysql_aurora.2.12.1"
  database_name             = var.db_name
  master_username           = var.db_username
  master_password           = var.db_password
  skip_final_snapshot       = true
}

resource "aws_rds_cluster_instance" "writer" {
  apply_immediately  = true
  cluster_identifier = aws_rds_cluster.rds-cluster.id
  identifier         = "writer"
  instance_class     = "db.t2.small"
  engine             = aws_rds_cluster.rds-cluster.engine
  engine_version     = aws_rds_cluster.rds-cluster.engine_version
}

resource "aws_rds_cluster_instance" "rds-reader1" {
  apply_immediately  = true
  cluster_identifier = aws_rds_cluster.rds-cluster.id
  identifier         = "reader1"
  instance_class     = "db.t2.small"
  engine             = aws_rds_cluster.rds-cluster.engine
  engine_version     = aws_rds_cluster.rds-cluster.engine_version
}

resource "aws_rds_cluster_instance" "rds-reader2" {
  apply_immediately  = true
  cluster_identifier = aws_rds_cluster.rds-cluster.id
  identifier         = "reader2"
  instance_class     = "db.t2.small"
  engine             = aws_rds_cluster.rds-cluster.engine
  engine_version     = aws_rds_cluster.rds-cluster.engine_version
}

resource "aws_rds_cluster_endpoint" "eligible" {
  cluster_identifier          = aws_rds_cluster.rds-cluster.id
  cluster_endpoint_identifier = "reader"
  custom_endpoint_type        = "READER"

  excluded_members = [
    aws_rds_cluster_instance.writer.id,
    aws_rds_cluster_instance.rds-reader1.id,
  ]
}

resource "aws_rds_cluster_endpoint" "static" {
  cluster_identifier          = aws_rds_cluster.rds-cluster.id
  cluster_endpoint_identifier = "static"
  custom_endpoint_type        = "READER"

  static_members = [
    aws_rds_cluster_instance.writer.id,
    aws_rds_cluster_instance.rds-reader2.id,
  ]
}
