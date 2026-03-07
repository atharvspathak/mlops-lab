# ── SSH Key ─────────────────────────────────────────────────
# = Your building access card
resource "linode_sshkey" "mlops" {
  label   = "${var.project}-key"
  ssh_key = trimspace(file("~/.ssh/id_ed25519.pub"))
}

# ── Linode VM ───────────────────────────────────────────────
# = Your developer workstation (EC2 equivalent)
resource "linode_instance" "iris_serving" {
  label  = "${var.project}-iris-serving"
  region = var.region

  # Free tier equivalent — smallest VM
  type  = "g6-nanode-1"  # 1 vCPU, 1GB RAM, 25GB disk

  # Ubuntu 22.04 LTS
  image = "linode/ubuntu22.04"
  private_ip = true
  # SSH access
  authorized_keys = [linode_sshkey.mlops.ssh_key]

  # Root password (for emergency console access)
  root_pass = var.root_password

  # Attach firewall (= attach security group)
  firewall_id = linode_firewall.iris_serving.id

  # Place in private subnet
  interface {
    purpose      = "vpc"
    subnet_id    = linode_vpc_subnet.private.id
    ipv4 {
      nat_1_1 = "any"  # gives public IP via NAT (like Elastic IP)
    }
  }

  # Bootstrap script — runs on first boot
  # = EC2 user_data
  stackscript_data = {}

 metadata {
    user_data = base64encode(<<-EOF
      #!/bin/bash
      # ── Update system ──────────────────────────────────────
      apt-get update -y

      # ── Install Docker ─────────────────────────────────────
      curl -fsSL https://get.docker.com | sh
      usermod -aG docker root

      # ── Install Nginx ──────────────────────────────────────
      apt-get install -y nginx

      # ── Configure Nginx as reverse proxy ───────────────────
      # = receptionist forwarding calls to dev team
      cat > /etc/nginx/sites-available/iris-serving <<'NGINX'
      server {
          listen 80;
          server_name _;

          location /health {
              proxy_pass http://localhost:8000/health;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
          }

          location /predict {
              proxy_pass http://localhost:8000/predict;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header Content-Type application/json;
          }

          location /metrics {
              proxy_pass http://localhost:8000/metrics;
              proxy_set_header Host $host;
          }

          location /docs {
              proxy_pass http://localhost:8000/docs;
              proxy_set_header Host $host;
          }
      }
      NGINX

      # ── Enable site ────────────────────────────────────────
      ln -sf /etc/nginx/sites-available/iris-serving \
             /etc/nginx/sites-enabled/iris-serving
      rm -f /etc/nginx/sites-enabled/default
      nginx -t && systemctl restart nginx
      systemctl enable nginx

      # ── Pull and run iris-serving ──────────────────────────
      docker pull ${var.dockerhub_username}/iris-serving:latest
      docker run -d \
        --name iris-serving \
        --restart always \
        -p 8000:8000 \
        ${var.dockerhub_username}/iris-serving:latest

      echo "✅ Setup complete" >> /var/log/mlops-setup.log
    EOF
    )
  }

  tags = [var.project]
}

# ── Outputs ─────────────────────────────────────────────────
output "vm_public_ip" {
  value       = tolist(linode_instance.iris_serving.ipv4)[0]
  description = "Public IP of iris-serving VM"
}

output "vm_private_ip" {
  value       = linode_instance.iris_serving.private_ip_address
  description = "Private IP of iris-serving VM"
}
