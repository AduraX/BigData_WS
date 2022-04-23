#!/usr/bin/env bash
if test "`echo -e`" = "-e" ; then ECHO=echo ; else ECHO="echo -e" ; fi

#region: arguements
source ../../AduraxFtns.sh
source hostFtns.sh

hostType=$1
StackExt=$2
isBastion=$3
NumMasters=$4
NumSlaves=$5
Prefix="K8s"
sshPORT=23
#endregion: arguements

#region: Set variables
K8s_Cluster_Name=K8s_${hostType}_$StackExt
ANSIBLE_USER=vagrant # ubuntu 
ANSIBLE_KEY=insecure_private_key # "~/.vagrant.d/insecure_private_key" 
HD_USER=$ANSIBLE_USER # hduser   
HD_PASS=hduser001
HD_KEY=$ANSIBLE_KEY #id_rsa.pub
PathToKey=/home/$USER/.ssh
StackName=BdCluster$isBastion$StackExt && $ECHO "$StackName" > StackNameFile

if test ! -f $PathToKey/id_rsa; then
  ssh-keygen -t rsa -N "" -f $PathToKey/id_rsa
  chmod 600 $PathToKey/id_rsa
  chmod 600 $PathToKey/id_rsa.pub
  touch $PathToKey/config; chmod 600 $PathToKey/config
fi
if test ! -f $PathToKey/$ANSIBLE_KEY; then cp ~/.vagrant.d/insecure_private_key $PathToKey/$ANSIBLE_KEY; chmod 600 $PathToKey/$ANSIBLE_KEY; fi
#endregion: Set variables

#region: Creating cluster on Vagrant 
sTime1=$(date +%s)
IP_BASE=$(CreateHost $NumMasters $NumSlaves) 
$ECHO "\nExecuting vagrant up command for Vagrant Cluster provisioning:"
vagrant up
timeDiff $sTime1 $(date +%s)
#endregion: Creating cluster on Vagrant 

#region: Get Stack Outputs
lbHosts="\n"
lbInventory=""

$ECHO "\n#~~~~~~~~ Connectivity configurations on .ssh/config file ~~~~~~~~~~" > $PathToKey/config
sshCmd="none"
if [ $isBastion == "Y" ]; then
  Host_Ip="${IP_BASE}.100"
  Host_Dns="127.0.0.1"
  Host_Port=${sshPORT}00
  LogDns=$Host_Dns
  $ECHO "\nHost LogHost  \n\tHostName $Host_Dns  \n\tUser $HD_USER \n\tPort $Host_Port \n\tIdentityFile $PathToKey/$HD_KEY \n\tProxyCommand none" >> $PathToKey/config
  $ECHO "${Prefix}-bastion$lbAZ" >> VagNodes
  sshCmd="ssh BastionA -W %h:%p"

  lbInventory="$lbInventory \n[Bastion]\n"
  lbHosts="${lbHosts}$Host_Ip bastion$lbAZ bastion$lbAZ.adurax.org \n"
  lbInventory="$lbInventory bastion$lbAZ ansible_ssh_host=$Host_Dns ansible_port=$Host_Port ansible_user=$ANSIBLE_USER  ansible_private_key_file=$PathToKey/$ANSIBLE_KEY \n" 
fi

lbInventory="$lbInventory \n[masters]\n"
for ((i=1; i<=NumMasters; i++)); do
  Psn=$(echo `printf "%2.0d\n" $i |sed "s/ /0/"`)
  Host_Ip="${IP_BASE}.1$Psn"
  Host_Dns="127.0.0.1"
  Host_Port="${sshPORT}$Psn"
  if [ $isBastion == "N" ] && [ $i -eq 1 ]; then
    LogDns=$Host_Dns
    $ECHO "\nHost LogHost  \n\tHostName $Host_Dns  \n\tUser $HD_USER \n\tPort $Host_Port \n\tIdentityFile $PathToKey/$HD_KEY \n\tProxyCommand none" >> $PathToKey/config
  fi
  if [ $i -eq 1 ]; then Master_IP=$Host_Ip; Master_Name=master$Psn$lbAZ; Master_Port=$Host_Port; fi
  $ECHO "${Prefix}-Master$Psn${lbAZ}" >> VagNodes
    
  lbHosts="${lbHosts}$Host_Ip  master$Psn$lbAZ  master$Psn$lbAZ.adurax.org \n"
  lbInventory="$lbInventory master$Psn$lbAZ ansible_ssh_host=$Host_Dns ansible_port=$Host_Port ansible_user=$ANSIBLE_USER  ansible_private_key_file=$PathToKey/$ANSIBLE_KEY \n" 
done

lbInventory="$lbInventory \n[slaves]\n"
for ((i=1; i<=NumSlaves; i++)); do
  Psn=`echo "$i + 10" | bc`
  Host_Ip="${IP_BASE}.1$Psn"
  Host_Dns="127.0.0.1"
  Host_Port="${sshPORT}$Psn"
  $ECHO "${Prefix}-Slave$Psn${lbAZ}" >> VagNodes
    
  lbHosts="${lbHosts}$Host_Ip slave$Psn$lbAZ  slave$Psn$lbAZ.adurax.org \n"
  lbInventory="$lbInventory slave$Psn$lbAZ ansible_ssh_host=$Host_Dns ansible_port=$Host_Port ansible_user=$ANSIBLE_USER  ansible_private_key_file=$PathToKey/$ANSIBLE_KEY \n" 
done

cat $PathToKey/config && chmod 600 $PathToKey/config
#endregion: Get Stack Outputs

#region: Creating Ansible Files
$ECHO "\nCreating Ansible files ...."
cp $PathToKey/id_rs*  ../../roles/k8s/common/templates 
$ECHO "StrictHostKeyChecking no \nUserKnownHostsFile=/dev/null" > ../../roles/k8s/common/templates/config 

$ECHO """---  
k8s_cluster_name: $K8s_Cluster_Name
k8s_master_admin_user: $HD_USER
k8s_master_admin_group: $HD_USER
k8s_node_admin_user: $HD_USER
k8s_node_admin_group: $HD_USER

k8s_master_node_name: $Master_Name
k8s_node_public_ip: $Master_IP #k8s_node_public_dns: $Master_Dns
""" > ../../group_vars/all.yml

$ECHO """127.0.0.1 localhost '{{inventory_hostname}}'
$lbHosts
# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts """ > ../../roles/k8s/common/templates/hosts.j2

$ECHO "$lbInventory" > ../../AnsibleInventory
#endregion: Creating Ansible Files

#region: Creating AnsibleRun.sh file
$ECHO "Creating connect.sh ..."
cat <<-strDOC > ../../connect.sh
#!/usr/bin/env bash

$ECHO "\nRunning connect.sh for Ansible ...."
eval \`ssh-agent -s\` # ssh-add -D # Remove all identities ==> Agent pid 5434
ssh-add -D  &&  ssh-add -k $PathToKey/$KeyNameEc2 # add your key to the SSH agent

$ECHO "\nRuning Ansible code ..."
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i AnsibleInventory k8s_bdPlat.yml
#$ECHO "\n\nJupyter url:  http://$LogDns:8899"

$ECHO "\nCopying config from K8s Cluster to localhost ..."
scp -P $Master_Port -i ~/.ssh/$HD_KEY $HD_USER@$Host_Dns:~/.kube/config ~/.kube/config 
$ECHO "\nInstall the Kubernetes Dashboard ..."  
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml 
$ECHO "\nA NodePort will be created to publish the kubernetes-dashboard ..."  
kubectl apply -f kubernetes-dashboard-service-np.yaml 
$ECHO "\nObtain an authentication token to use on the Kubernetes-dashboard authentication ..."  
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep "admin-user" | awk '{print $1}')
$ECHO "\nAccess the Dashboard using the URL https://$Master_IP:30002/#/login \nusing the token printed earlier ..."
$ECHO "\nSshing into $LogHost ..."
ssh LogHost
strDOC
chmod +x ../../connect.sh
#endregion: Creating connect.sh file
