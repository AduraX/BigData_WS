#!/usr/bin/env bash

echo -e "\nRunning connect.sh for Ansible ...."
eval `ssh-agent -s` # ssh-add -D # Remove all identities ==> Agent pid 5434
ssh-add -D  &&  ssh-add -k /home/prado/.ssh/ # add your key to the SSH agent

echo -e "\nRuning Ansible code ..."
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i AnsibleInventory k8s_bdPlat.yml
#echo -e "\n\nJupyter url:  http://127.0.0.1:8899"

echo -e "\nCopying config from K8s Cluster to localhost ..."
scp -P 2301 -i ~/.ssh/insecure_private_key vagrant@127.0.0.1:~/.kube/config ~/.kube/config 
echo -e "\nInstall the Kubernetes Dashboard ..."  
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml 
echo -e "\nA NodePort will be created to publish the kubernetes-dashboard ..."  
kubectl apply -f kubernetes-dashboard-service-np.yaml 
echo -e "\nObtain an authentication token to use on the Kubernetes-dashboard authentication ..."  
kubectl -n kubernetes-dashboard describe secret 
echo -e "\nAccess the Dashboard using the URL https://192.168.70.101:30002/#/login \nusing the token printed earlier ..."
echo -e "\nSshing into  ..."
ssh LogHost
