TF_DIR=terraform

init:
	terraform -chdir=$(TF_DIR) init

init-local:
	terraform -chdir=$(TF_DIR) init -backend=false

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) validate

plan:
	terraform -chdir=$(TF_DIR) plan

apply:
	terraform -chdir=$(TF_DIR) apply

destroy:
	terraform -chdir=$(TF_DIR) destroy

output:
	terraform -chdir=$(TF_DIR) output

install-ansible:
	ansible-galaxy install -r ansible/requirements.yml
	ansible-galaxy collection install -r ansible/requirements.yml

inventory:
	echo "[web]" > ansible/inventory.ini
	terraform -chdir=$(TF_DIR) output -json web_server_public_ips | jq -r '.[] + " ansible_user=ubuntu"' >> ansible/inventory.ini

deploy:
	ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-vault-pass -e redmine_db_host=$$(terraform -chdir=$(TF_DIR) output -raw postgres_host)

deploy-prepare:
	ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-vault-pass --tags prepare -e redmine_db_host=$$(terraform -chdir=$(TF_DIR) output -raw postgres_host)

deploy-app:
	ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-vault-pass --tags deploy -e redmine_db_host=$$(terraform -chdir=$(TF_DIR) output -raw postgres_host)

deploy-monitoring:
	ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-vault-pass --tags monitoring -e redmine_db_host=$$(terraform -chdir=$(TF_DIR) output -raw postgres_host)

prepare:
	ansible-playbook ansible/generate_tfvars.yml --ask-vault-pass