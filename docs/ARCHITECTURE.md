# Architecture logique

```text
Internet
   |
   v
Application Load Balancer (public subnet A + B)
   |
   +--------------------------+
   |                          |
   v                          v
EC2 Auto Scaling (private app A)  EC2 Auto Scaling (private app B)
   |                          |
   +-------------+------------+
                 |
                 v
       RDS PostgreSQL (private DB A + B)

Private app subnets -- NAT Gateway(s) --> Internet (sortie contrôlée)
Private app route tables -- S3 Gateway Endpoint --> S3
Terraform CLI / GitHub Actions --> S3 remote state (versioning + encryption + lockfile)
```

Le trafic entrant public est limité à l'ALB. Les instances n'acceptent le port 80 que depuis le SG ALB. RDS n'accepte 5432 que depuis le SG applicatif. Les instances n'ont pas de port SSH entrant; l'accès d'administration prévu est AWS Systems Manager.
