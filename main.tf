# 1. Configuration des fournisseurs
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3" # Paris
}

# 2. Réseau (VPC)
resource "aws_vpc" "main_network" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "VPC-ScanWise" }
}

# 3. Sous-réseau Public
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_network.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"
  tags = { Name = "Subnet-ScanWise" }
}

# 4. Internet Gateway & Routage
resource "aws_internet_gateway" "main_gw" {
  vpc_id = aws_vpc.main_network.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_network.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. Sécurité (Pare-feu)
resource "aws_security_group" "web_sg" {
  name   = "web-access"
  vpc_id = aws_vpc.main_network.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 6. Serveur EC2 avec Portfolio Final
resource "aws_instance" "app_server" {
  ami           = "ami-01d21b7be69801c2f" # Ubuntu 24.04 à Paris
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2
              sudo rm -f /var/www/html/index.html

              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html lang="fr">
              <head>
                  <meta charset="UTF-8">
                  <title>ScanWise | Sandra Kenfack</title>
                  <style>
                      body { font-family: 'Segoe UI', sans-serif; background-color: #0f172a; color: white; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                      .card { background: #1e293b; border-radius: 20px; padding: 40px; max-width: 550px; box-shadow: 0 20px 50px rgba(0,0,0,0.5); border: 1px solid #334155; text-align: center; }
                      h1 { color: #38bdf8; font-size: 2.2em; margin-bottom: 10px; }
                      p { color: #94a3b8; line-height: 1.6; margin-bottom: 25px; }
                      .badge { background: #0369a1; color: #bae6fd; padding: 6px 15px; border-radius: 50px; font-size: 0.8em; font-weight: bold; text-transform: uppercase; margin-bottom: 15px; display: inline-block; }
                      
                      .btn-container { display: flex; gap: 10px; justify-content: center; margin-top: 25px; flex-wrap: wrap; }
                      
                      .btn { padding: 10px 18px; border-radius: 8px; font-weight: bold; text-decoration: none; transition: all 0.3s; font-size: 0.85em; }
                      
                      .btn-linkedin { background-color: #0077b5; color: white; border: 1px solid #0077b5; }
                      .btn-github { background-color: #24292e; color: white; border: 1px solid #444; }
                      .btn-portfolio { background-color: transparent; border: 1px solid #38bdf8; color: #38bdf8; }
                      
                      .btn:hover { transform: translateY(-3px); opacity: 0.9; }
                      
                      .status { margin-top: 30px; padding-top: 20px; border-top: 1px solid #334155; font-size: 0.8em; color: #4ade80; font-weight: bold; }
                  </style>
              </head>
              <body>
                  <div class="card">
                      <span class="badge">Cloud Architecture & DevOps</span>
                      <h1>Projet ScanWise</h1>
                      <p>Interface de <strong>Sandra Kenfack Dongmo</strong>.<br>Infrastructure Web automatisée sur AWS.</p>
                      
                      <div class="btn-container">
                          <a href="https://www.linkedin.com/in/sandra-kenfack-dongmo-48b8411a6" target="_blank" class="btn btn-linkedin">LinkedIn</a>
                          <a href="https://github.com/sandrakenfack" target="_blank" class="btn btn-github">GitHub</a>
                          <a href="http://sandrakenfack.github.io/" target="_blank" class="btn btn-portfolio">Portfolio</a>
                      </div>
                      
                      <div class="status">● Déploiement AWS Paris : Succès</div>
                  </div>
              </body>
              </html>
              HTML
              EOF

  tags = { Name = "Serveur-ScanWise-App" }
}

# 7. Sortie IP
output "adresse_ip_publique" {
  value = aws_instance.app_server.public_ip
}