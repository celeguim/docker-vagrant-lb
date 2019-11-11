.PHONY: up vagrant playbook smoketest test clean

up: vagrant playbook

vagrant:
	@vagrant up
	@vagrant ssh-config > ssh.config

playbook:
	@ansible-playbook -i inventories/vagrant.yml swarm.yml -vvv

smoketest:
	@ansible-playbook -i inventories/vagrant.yml swarm.yml --tags test

test:
	@molecule test

clean:
	@vagrant destroy -f
	@rm -rf kubernetes-resources
	@[ ! -f ssh.config ] || rm ssh.config
