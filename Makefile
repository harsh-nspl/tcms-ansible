.PHONY: help install lint deploy-war deploy-batch rollback site test

INVENTORY ?= dev
ANSIBLE_OPTS ?=

help:
	@echo "TCMS Ansible Automation"
	@echo ""
	@echo "Usage: make <target> [INVENTORY=dev|staging|prod]"
	@echo ""
	@echo "Targets:"
	@echo "  install      Install Ansible Galaxy requirements"
	@echo "  lint         Run ansible-lint on playbooks"
	@echo "  deploy-war   Deploy WAR to tomcat servers"
	@echo "  deploy-batch Deploy batch JAR"
	@echo "  rollback     Rollback last deployment"
	@echo "  site         Run full site.yml playbook"
	@echo "  test         Run syntax check on all playbooks"

install:
	ansible-galaxy collection install -r requirements.yml --force

lint:
	ansible-lint playbooks/*.yml playbooks/roles/*/tasks/*.yml

deploy-war:
	ansible-playbook -i inventories/$(INVENTORY)/hosts.ini playbooks/deploy.yml \
		-e deploy_type=war $(ANSIBLE_OPTS)

deploy-batch:
	ansible-playbook -i inventories/$(INVENTORY)/hosts.ini playbooks/deploy.yml \
		-e deploy_type=batch $(ANSIBLE_OPTS)

rollback:
	ansible-playbook -i inventories/$(INVENTORY)/hosts.ini playbooks/rollback.yml \
		-e deploy_type=$(DEPLOY_TYPE) $(ANSIBLE_OPTS)

site:
	ansible-playbook -i inventories/$(INVENTORY)/hosts.ini playbooks/site.yml $(ANSIBLE_OPTS)

test:
	ansible-playbook --syntax-check playbooks/*.yml
