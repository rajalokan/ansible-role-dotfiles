
all:
	ansible-playbook -i "localhost," setup.yml

vi:
	ansible-playbook -i "localhost," setup.yml --tags vim

shell_bash:
	ansible-playbook -i "localhost," setup.yml --tags bash

docker:
	ansible-playbook -i "localhost," setup.yml --tags docker

git:
	ansible-playbook -i "localhost, " setup.yml --tags git

python:
	ansible-playbook -i "localhost, " setup.yml --tags python
