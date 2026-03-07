# ── VPC ─────────────────────────────────────────────────────
# = Your office building
resource "linode_vpc" "mlops" {
  label  = "${var.project}-vpc"
  region = var.region
}

# ── Public Subnet ───────────────────────────────────────────
# = Ground floor reception (internet facing)
resource "linode_vpc_subnet" "public" {
  vpc_id = linode_vpc.mlops.id
  label  = "${var.project}-public"
  ipv4   = "10.0.1.0/24"
}

# ── Private Subnet ──────────────────────────────────────────
# = 2nd floor dev office (internal only)
resource "linode_vpc_subnet" "private" {
  vpc_id = linode_vpc.mlops.id
  label  = "${var.project}-private"
  ipv4   = "10.0.2.0/24"
}

# ── Firewall (= AWS Security Group) ─────────────────────────
# Controls who can reach iris-serving
resource "linode_firewall" "iris_serving" {
  label = "${var.project}-iris-serving-fw"

  # Inbound rules — who can reach us
  inbound {
    label    = "allow-http"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "80"
    ipv4     = ["0.0.0.0/0"]  # internet reaches Nginx on port 80
  }

  inbound {
    label    = "allow-ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = ["0.0.0.0/0"]
  }

  inbound {
    label    = "allow-nodebalancer"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "8000"
    ipv4     = ["192.168.255.0/24"]
  }

  # Remove allow-api and allow-https rules
  # Port 8000 NOT open to internet — only Nginx reaches it locally

  # Default inbound policy — block everything else
  inbound_policy = "DROP"

  # Outbound rules — where we can go
  outbound_policy = "ACCEPT"  # allow all outbound (pull images, updates)

  # Attach to our VM (added when we create the VM)
  linodes = []
}

# ── Outputs ─────────────────────────────────────────────────
output "vpc_id" {
  value = linode_vpc.mlops.id
}

output "public_subnet_id" {
  value = linode_vpc_subnet.public.id
}

output "private_subnet_id" {
  value = linode_vpc_subnet.private.id
}

output "firewall_id" {
  value = linode_firewall.iris_serving.id
}
