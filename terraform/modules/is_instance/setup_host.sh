#!/usr/bin/env bash

NODE_ROLE=$1
USER_PASSWORD=$2

set -o errexit
set -o nounset

grep -q "ChallengeResponseAuthentication" /etc/ssh/sshd_config && sed -i "/^[#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication no" >>/etc/ssh/sshd_config
grep -q "PasswordAuthentication" /etc/ssh/sshd_config && sed -i "/^[#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >>/etc/ssh/sshd_config
grep -q "#PubkeyAuthentication" /etc/ssh/sshd_config && sed -i "/^[#]*PubkeyAuthentication[[:space:]]yes/c\PubkeyAuthentication yes" /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" >>/etc/ssh/sshd_config
service sshd restart

passwd -d root

useradd user
echo "${USER_PASSWORD}" | passwd --stdin user
cat > /etc/sudoers.d/user <<EOF
user ALL=(ALL) NOPASSWD: ALL
EOF

sleep 60
subscription-manager refresh
subscription-manager repos --enable=*
yum update -y -q

"/tmp/onboarding_script_${NODE_ROLE}.sh"
