#!/usr/bin/env bash
eval `ssh-agent -s` # ssh-add -D # Remove all identities ==> Agent pid 5434
ssh-add -D  &&  ssh-add -k /home/dasc/.ssh/SingaporeKeyEc2.pem # add your key to the SSH agent

echo -e "\nRuning Ansible code ..."
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i AnsibleInventory bdplat_pb.yml
echo -e "\n\nJupyter url:  http://127.0.0.1:8899"
ssh LogHost
