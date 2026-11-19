# Terraform AWS Cloud Platform with CI/CD

Infrastructure AWS modulaire déployée avec Terraform et GitHub Actions.

## Architecture
- VPC `10.20.0.0/16`, 2 Availability Zones.
- 2 subnets publics (ALB + NAT), 2 subnets privés applicatifs (ASG EC2), 2 subnets privés DB (RDS).
- Application Load Balancer, Launch Template, Auto Scaling Group.
- RDS PostgreSQL privé avec mot de passe géré par AWS Secrets Manager.
- Bucket S3 privé, chiffré, versionné.
- Backend Terraform S3 avec chiffrement, versioning et verrouillage natif `use_lockfile`.
- IAM role EC2 pour Session Manager (pas de SSH ouvert).

> Important : ce dépôt est un modèle de projet. Vérifie les quotas et permissions de ton compte AWS avant `apply`.
> Les comptes AWS Academy peuvent interdire certaines opérations IAM, EC2, RDS, ALB ou NAT Gateway.
> Le déploiement complet peut générer des frais importants. Déploie `dev`, valide, puis détruis-le.

## Prérequis
- Terraform >= 1.10.0
- AWS CLI v2
- Git
- Un compte AWS avec permissions sur VPC, EC2, ELB, Auto Scaling, RDS, S3, IAM, KMS/Secrets Manager.
- GitHub repository si tu actives le pipeline.

Vérifier :
```bash
terraform version
aws --version
aws sts get-caller-identity
```

## 1. Authentification AWS locale
Ne mets jamais les clés dans les fichiers `.tf` ou `.tfvars`.

Pour un profil AWS local :
```bash
aws configure --profile terraform-lab
aws sts get-caller-identity --profile terraform-lab
```
PowerShell :
```powershell
$env:AWS_PROFILE="terraform-lab"
$env:AWS_REGION="eu-west-1"
```
Linux/macOS :
```bash
export AWS_PROFILE=terraform-lab
export AWS_REGION=eu-west-1
```

AWS Academy : les credentials du Learner Lab sont temporaires. Utilise les credentials de session dans l'environnement local et relance le lab avant expiration. Ne les place jamais dans GitHub comme clés permanentes.

## 2. Bootstrap du backend S3 (à faire une seule fois)
Le backend ne peut pas créer le bucket qui va stocker son propre state. Il faut donc créer le bucket séparément.

```bash
cd bootstrap
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Le bucket doit être dans la même région que celle indiquée dans `backend.hcl`. Le nom S3 doit être globalement unique.

Après création, note le nom du bucket. Ne détruis pas ce bucket tant que les états Terraform des environnements existent.

## 3. Initialiser un environnement
Exemple `dev` (PowerShell ou Bash) :
```bash
cd ../environments/dev
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
```

Le fichier `backend.hcl` contient le nom du bucket, la région et la clé d'état. Modifie-le avec ton bucket.

Répète avec `test` ou `prod` seulement après validation de `dev`.
Chaque environnement utilise une clé S3 différente : `dev/terraform.tfstate`, `test/terraform.tfstate`, `prod/terraform.tfstate`.

## 4. Variables
Chaque environnement contient `terraform.tfvars`. Modifie au minimum :
- `owner`
- `aws_region`
- `project_name`
- `db_instance_class` selon les capacités du compte
- `certificate_arn` si tu veux activer HTTPS avec un certificat ACM dans la même région

Aucun mot de passe DB n'est demandé : RDS gère automatiquement le secret maître dans Secrets Manager.
Ne versionne pas de fichier `.tfvars` personnel contenant des données sensibles.

## 5. Déploiement et vérifications
Après `apply`, récupère l'URL :
```bash
terraform output alb_dns_name
terraform output application_url
terraform output rds_endpoint
```
Ouvre `application_url`. Rafraîchis plusieurs fois : le hostname affiché doit changer lorsque l'ALB distribue les requêtes.

Vérifie l'ASG et les Target Groups dans la console EC2. Les deux instances doivent devenir `InService` et les targets `healthy`.

### Test de panne
1. Vérifie d'abord que les deux targets sont healthy.
2. Arrête une instance EC2 depuis la console (ou termine-la).
3. Recharge l'URL de l'ALB : l'autre instance doit continuer à répondre.
4. L'ASG doit recréer une instance pour revenir à la capacité désirée.

### Vérification DB
RDS est configuré `publicly_accessible = false` et son SG n'autorise PostgreSQL (5432) que depuis le SG applicatif. Ne teste pas en ouvrant temporairement la DB à `0.0.0.0/0`.

## 6. Détruire pour maîtriser les coûts
Dans chaque environnement :
```bash
terraform plan -destroy
terraform destroy
```
Détruis d'abord `prod` si tu l'as créé, puis `test`, puis `dev`. Garde le bucket bootstrap jusqu'à suppression de tous les states. Supprime ensuite le backend uniquement si tu n'en as plus besoin.

Attention : NAT Gateway, ALB, RDS, EC2 et stockage peuvent coûter même quand le trafic est nul. Vérifie la console Billing/Cost Explorer.

## 7. GitHub Actions
Le workflow `.github/workflows/terraform.yml` :
- Sur Pull Request : fmt, init sans backend, validate, TFLint et Checkov (aucun credential AWS n'est exposé à du code non fusionné).
- Sur push vers `main` : plan `dev` avec AWS OIDC et sauvegarde temporaire du plan comme artefact privé du dépôt.
- Sur lancement manuel : choix `dev/test/prod` et `plan/apply`. Le job utilise un GitHub Environment; configure une approbation obligatoire pour `test` et `prod`.

### Configuration GitHub recommandée
1. Crée un IAM OIDC provider GitHub dans AWS (si le compte l'autorise).
2. Crée un rôle IAM dédié au pipeline, limité au dépôt et à la branche `main`.
3. Ajoute les variables GitHub Actions :
   - `AWS_ROLE_ARN`
   - `AWS_REGION`
   - `TF_STATE_BUCKET`
4. Dans Settings > Environments, crée `dev`, `test`, `prod`. Active Required reviewers pour `test` et `prod`.
5. Protège `main` : Pull Request obligatoire et aucune application depuis une branche non protégée.

AWS Academy peut ne pas autoriser la création d'un OIDC provider ou d'un rôle IAM. Dans ce cas, garde le pipeline PR sans accès AWS et exécute le plan/apply depuis ton poste avec les credentials temporaires du Learner Lab. N'utilise pas des clés temporaires qui expirent comme secrets permanents GitHub.

## 8. Dépannage rapide
| Erreur | Cause probable | Solution |
|---|---|---|
| `No valid credential sources found` | Credentials absents/expirés | `aws sts get-caller-identity`, relancer le Learner Lab ou le profil |
| `AccessDenied` | Politique AWS Academy/SCP/IAM | Identifier l'action refusée; demander un rôle/compte autorisé ou retirer la ressource interdite avec justification |
| `BucketAlreadyExists` | Nom S3 global déjà pris | Choisir un autre nom unique |
| `Error acquiring the state lock` | Autre exécution ou lock abandonné | Vérifier qu'aucun Terraform ne tourne; `terraform force-unlock` seulement après vérification |
| `InvalidSubnet` / AZ | Mauvaise région ou AZ | Vérifier `aws_region` et les AZ disponibles |
| ALB target unhealthy | Nginx non installé, SG, route NAT ou mauvais health check | Vérifier user-data/cloud-init, SG ALB→EC2, NAT et `/` sur port 80 |
| RDS creation failed | Classe non disponible/quota/limite compte | Choisir une classe autorisée et vérifier quotas RDS |
| `InvalidParameterCombination` | Paramètre non supporté par la classe/région | Utiliser une classe disponible et supprimer les paramètres non compatibles |
| GitHub OIDC AccessDenied | Trust policy ou rôle incorrect | Vérifier `sub`, `aud`, repo, branche et permissions `id-token: write` |
| `Backend configuration changed` | Backend modifié | `terraform init -reconfigure` ou `-migrate-state` selon le cas |

Ne lance jamais `terraform force-unlock`, `-reconfigure`, `-migrate-state` ou `destroy` sans comprendre l'effet sur le state.

## 9. Livrables du cahier des charges
- [ ] Code Terraform des modules et environnements.
- [ ] `terraform.tfvars.example` sans secret.
- [ ] README et schéma d'architecture.
- [ ] Pipeline avec fmt, validate, plan.
- [ ] Captures VPC/subnets, ALB/targets, ASG/EC2, RDS privé, S3, backend.
- [ ] URL Web et test de panne.
- [ ] Estimation des coûts.
- [ ] Rapport 10–15 pages et présentation.
