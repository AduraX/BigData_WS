#!/usr/bin/env bash
if test "`echo -e`" = "-e" ; then ECHO=echo ; else ECHO="echo -e" ; fi

CreateHost() { # para: NumMasters NumSlaves
if test ! -e "Vagrantfile"; then
#[**
i=0; #> Starting reading fro line 5 | parItem = 1st Item, OtherItem=2nd item after splitting with '#'
while IFS="#" read -r parItem OtherItem ; do
  if [ $i -eq 6 ]; then
    mMEM=`echo $parItem | sed 's/ *$//g'`
  elif [ $i -eq 7 ]; then
    sMEM=`echo $parItem | sed 's/ *$//g'`
  elif [ $i -eq 8 ]; then
    mCPU=`echo $parItem | sed 's/ *$//g'`
  elif [ $i -eq 9 ]; then
    sCPU=`echo $parItem | sed 's/ *$//g'`
  elif [ $i -eq 10 ]; then
    ipBASE=`echo $parItem | sed 's/ *$//g'`
  else
    sshPORT=`echo $parItem | sed 's/ *$//g'`
  fi
  i=$((i+1)) # && echo -e "\ni: $i | j: $j <==> $OtherItem"
done < parameters.lt
#echo -e "\nmMeM: $mMEM | sMeM: $sMEM | mCPU: $mCPU | sCPU: $sCPU | ipBASE: $ipBASE | sshPORT: $sshPORT"
#**]

#[**
cat >> "Vagrantfile" <<- EndOfVagrantfile
# -*- mode: ruby -*- \n# vi: set ft=ruby :

MASTERS_NUM=$1
SLAVES_NUM=$2
MASTERS_MEM=$mMEM
SLAVES_MEM=$sMEM
MASTERS_CPU=$mCPU
SLAVES_CPU=$sCPU
IP_BASE='$ipBASE'
SSH_PORT=$sshPORT

VAGRANT_DISABLE_VBOXSYMLINKCREATE=1
IMAGE_NAME = "bento/ubuntu-20.04"

Vagrant.configure("2") do |config|
    config.ssh.insert_key = false

    (1..MASTERS_NUM).each do |i|
        config.vm.define "Master0#{i}" do |master|
            master.vm.box = IMAGE_NAME
            master.vm.network "private_network", ip: "#{IP_BASE}.10#{i}"
        		master.vm.network :forwarded_port, guest: 22, host: "220#{i}".to_i(), id: "ssh"

        		master.vm.network :forwarded_port, guest: 7077, host: 7077, auto_correct: true # spark_master_port
        		master.vm.network :forwarded_port, guest: 8080, host: 8080, auto_correct: true # spark_master_webui_port
        		master.vm.network :forwarded_port, guest: 4040, host: 4040, auto_correct: true # Spark driver UI
        		master.vm.network :forwarded_port, guest: 4041, host: 4041, auto_correct: true # Spark driver UI for the 2nd application (e.g. a command-line job)

            master.vm.hostname = "Master0#{i}"
            master.vm.provider "virtualbox" do |v|
                v.memory = MASTERS_MEM
                v.cpus = MASTERS_CPU
            end
        end
    end

    (1..SLAVES_NUM).each do |j|
        config.vm.define "Slave#{10 + j}" do |slave|
            slave.vm.box = IMAGE_NAME
            slave.vm.network "private_network", ip: "#{IP_BASE}.1#{10 + j}"
        		slave.vm.network "forwarded_port", guest: 22, host: "22#{10 + j}".to_i(), id: "ssh"
        		slave.vm.network :forwarded_port, guest: 7011, host: 7011, auto_correct: true # spark_worker_port
        		slave.vm.network :forwarded_port, guest: 8011, host: 8011, auto_correct: true # spark_worker_webui_port
            slave.vm.hostname = "Slave#{10 + j}"
            slave.vm.provider "virtualbox" do |v|
                v.memory = SLAVES_MEM
                v.cpus = SLAVES_CPU
            end
        end
    end
end
EndOfVagrantfile
#**]
fi
echo $ipBASE # return '$ipBASE'
}
