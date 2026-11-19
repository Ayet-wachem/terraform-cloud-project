# Checklist de déploiement et démonstration

## Avant le déploiement
- [ ] Région et deux AZ vérifiées.
- [ ] AWS credentials valides (`aws sts get-caller-identity`).
- [ ] Permissions AWS vérifiées.
- [ ] Budget/alertes de coûts configurés.
- [ ] Bucket backend créé par bootstrap.
- [ ] Backend `backend.hcl` configuré localement (non versionné).
- [ ] Variables `terraform.tfvars` créées à partir de l'exemple.
- [ ] Aucun secret dans Git.

## Après `terraform apply`
- [ ] VPC et 6 subnets visibles.
- [ ] Internet Gateway et NAT Gateway opérationnels.
- [ ] ALB actif dans 2 subnets publics.
- [ ] ASG avec 2 instances dans 2 AZ.
- [ ] Target Group : 2 targets healthy.
- [ ] URL ALB affiche la page de démonstration.
- [ ] RDS `Publicly accessible = No`.
- [ ] RDS Security Group n'autorise que le SG applicatif.
- [ ] Bucket S3 privé, versioning et chiffrement activés.
- [ ] Backend state présent dans S3 et versioning actif.

## Captures à prendre
1. Pipeline PR (fmt, validate, TFLint, Checkov).
2. Pipeline plan sur main et plan lisible.
3. VPC + subnets.
4. ALB + listeners + Target Group healthy.
5. Auto Scaling Group + deux instances.
6. RDS privé.
7. Bucket S3 et propriétés de sécurité.
8. Bucket backend et versions du state.
9. Page Web avec hostname.
10. Test de panne (avant/après).

## Nettoyage
- [ ] `terraform destroy` pour chaque environnement non conservé.
- [ ] Vérifier EC2, ALB, NAT Gateway, EIP et RDS supprimés.
- [ ] Garder le backend tant que le state est utile.
