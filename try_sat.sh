DEBUG=true
export BASE_DIR=$(pwd)

if [ -n "$DEBUG" ]; then
	set -x
fi

install () {
	# Unfortunately the ibmcloud CLI does not give an appropriate RC when
	# ibmcloud plugin update fails, so it's not easy to automate this
	# elegantly. You may get duplicate messages as plugins are both
	# installed and updated.
	ibmcloud plugin install container-registry
	ibmcloud plugin install container-service
	ibmcloud plugin install observe-service
	ibmcloud plugin install vpc-infrastructure
	ibmcloud plugin update container-registry
	ibmcloud plugin update container-service
	ibmcloud plugin update observe-service
	ibmcloud plugin update vpc-infrastructure
}

watch () {
	./watch_ibmcloud
}

terraform_init () {
	cd $BASE_DIR/terraform
	terraform init -upgrade
}	

clean () {
	terraform_init 
	ssh-keys/ssh-key 
	login_ibmcloud
	echo "Clean is starting in 5 seconds, Ctrl-C if you don't want to proceed..."
	@sleep 5
	rm -fv wireguard-$RESOURCE_PREFIX.conf
	while ibmcloud oc cluster get --cluster "$RESOURCE_PREFIX-cluster" 2>/dev/null >/dev/null; do 
		ibmcloud oc cluster rm -f --cluster "$RESOURCE_PREFIX-cluster"; 
		echo 'Waiting for cluster to be deleted...'; 
		sleep 30; 
	done
	cd $BASE_DIR/terraform
	terraform destroy -auto-approve && rm -fv terraform.tfstate*
	rm -fv $BASE_DIR/terraform/ssh-keys/ssh-key
	rm -fv $BASE_DIR/terraform/ssh-keys/ssh-key.pub
}

ssh-keys/ssh-key () {
	mkdir -p $BASE_DIR/ssh-keys/
	ssh-keygen -f $BASE_DIR/ssh-keys/ssh-key -N ''
}

login_ibmcloud () {
	ibmcloud login --apikey "$IC_API_KEY" -r "$LOCATION_REGION"
}

login_ibmcloud_silent () { 
	login_ibmcloud 2>&1 >/dev/null
}

target () {
	terraform_init 
	login_ibmcloud
	cd $BASE_DIR/terraform && terraform apply -target=ibm_resource_group.group -auto-approve
	ibmcloud target -g "$RESOURCE_PREFIX-group" -r "$LOCATION_REGION"
}

apply_terraform () {
	terraform_init 
	ssh-keys/ssh-key
	terraform apply -auto-approve
}

attach_host_ready () {
	until [ $(ibmcloud sat host ls --location "$RESOURCE_PREFIX-location" | grep Ready | grep unassigned | wc -l) -gt 5 ]; do echo 'Waiting for 6 hosts to be attached...'; sleep 30; login_ibmcloud_silent; done
}

setup_dns_controlplane () {
	# For more information, see http://ibm.biz/satloc-ts-subdomain
	
	scripts/dns-register "$RESOURCE_PREFIX-location" $(cd $BASE_DIR/terraform && terraform output -raw ipaddress_controlplane01_floating) $(cd $BASE_DIR/terraform && terraform output -raw ipaddress_controlplane02_floating) $(cd $BASE_DIR/terraform && terraform output -raw ipaddress_controlplane03_floating)
}

remove_and_reassign_host () {
	echo "removing and reassigning $1"
}

assign_controlplane () {
	until ibmcloud sat host assign --location "$RESOURCE_PREFIX-location" --zone=location-zone-1 --host="$RESOURCE_PREFIX-controlplane01"; do echo 'Waiting to assign host to control plane 01'; sleep 30; done
	until ibmcloud sat host assign --location "$RESOURCE_PREFIX-location" --zone=location-zone-2 --host="$RESOURCE_PREFIX-controlplane02"; do echo 'Waiting to assign host to control plane 02'; sleep 30; done
	until ibmcloud sat host assign --location "$RESOURCE_PREFIX-location" --zone=location-zone-3 --host="$RESOURCE_PREFIX-controlplane03"; do echo 'Waiting to assign host to control plane 03'; sleep 30; done
}

assign_controlplane_ready () {
	until ibmcloud sat location get --location "$RESOURCE_PREFIX-location" | grep -E 'Message|Mensaje' | grep R0001; do echo 'Waiting for control plane to be assigned and location to be ready.'; sleep 60; login_ibmcloud_silent; done
}

create_cluster () {
	target
	DEFAULT_KS_VERSION=$(ibmcloud ks versions --json | jq '.openshift[] | select(.default == true)')
	export DEFAULT_MAJOR_VERSION=$(echo $DEFAULT_KS_VERSION | jq '.major' 2> /dev/null)
	export DEFAULT_MINOR_VERSION=$(echo $DEFAULT_KS_VERSION | jq '.minor' 2> /dev/null)
	export DEFAULT_PATCH_VERSION=$(echo $DEFAULT_KS_VERSION | jq '.patch' 2> /dev/null)
	until ibmcloud oc cluster create satellite -q --location "$RESOURCE_PREFIX-location" --name "$RESOURCE_PREFIX-cluster" --version $DEFAULT_MAJOR_VERSION.$DEFAULT_MINOR_VERSION.$(echo $DEFAULT_PATCH_VERSION)_openshift --enable-config-admin; do echo 'Waiting to create cluster...'; sleep 30; login_ibmcloud_silent; done
}

cluster_in_warning () {
	# Cluster is ready once it moves to "warning" state (the warning is because it will have no worker nodes yet).
	until ibmcloud oc cluster get --cluster "$RESOURCE_PREFIX-cluster" 2>/dev/null | grep 'State.*warning' >/dev/null; do echo 'Waiting on cluster to move to "warning" status...'; sleep 30; login_ibmcloud_silent; done
}

cluster_in_normal () {
	until ibmcloud oc cluster get --cluster "$RESOURCE_PREFIX-cluster" 2>/dev/null | grep 'State.*normal' >/dev/null; do echo 'Waiting on cluster to move to "normal" status...'; sleep 30; login_ibmcloud_silent; done
}

assign_workernodes () {
	until ibmcloud sat host assign --location "$RESOURCE_PREFIX-location" --worker-pool=default --host="$RESOURCE_PREFIX-workernode01" --cluster "$RESOURCE_PREFIX-cluster"; do echo 'Waiting to assign worker node 01...'; sleep 30; done
	until ibmcloud sat host assign --location "$RESOURCE_PREFIX-location" --worker-pool=default --host="$RESOURCE_PREFIX-workernode02" --cluster "$RESOURCE_PREFIX-cluster"; do echo 'Waiting to assign worker node 02...'; sleep 30; done
	until ibmcloud sat host assign --location "$RESOURCE_PREFIX-location" --worker-pool=default --host="$RESOURCE_PREFIX-workernode03" --cluster "$RESOURCE_PREFIX-cluster"; do echo 'Waiting to assign worker node 03...'; sleep 30; done
}

login_cluster () {
	get_cluster_config
	oc login -u apikey -p IC_API_KEY
}

setup_network_cluster () {
	scripts/nlb-dns-remove "$RESOURCE_PREFIX-cluster"
	scripts/nlb-dns-add "$RESOURCE_PREFIX-cluster" $(cd $BASE_DIR/terraform && terraform output -raw ipaddress_workernode01_floating) $(cd $BASE_DIR/terraform && terraform output -raw ipaddress_workernode02_floating) $(cd $BASE_DIR/terraform && terraform output -raw ipaddress_workernode03_floating)
}

get_cluster_config () {
	login_ibmcloud
	ibmcloud oc cluster config --cluster "$RESOURCE_PREFIX-cluster" --admin
}

configure_cluster_logdna () {
	get_cluster_config
	oc adm new-project --node-selector='' ibm-observe
	oc create serviceaccount logdna-agent -n ibm-observe
	oc adm policy add-scc-to-user privileged system:serviceaccount:ibm-observe:logdna-agent
	oc create secret generic logdna-agent-key --from-literal=logdna-agent-key=$(cd $BASE_DIR/terraform && terraform output -raw logdna_ingestion_key) -n ibm-observe
	oc create -f https://assets.us-east.logging.cloud.ibm.com/clients/logdna-agent-ds-os.yaml -n ibm-observe
}

wireguard-conf () {
	ssh-keys/ssh-key
	# There is no point in having strict host key checking, as floating IPs may get reused and we'll only connect to this server once.
	scp -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i ssh-keys/ssh-key root@$(cd $BASE_DIR/terraform && terraform output -raw ipaddress_wireguard_floating):wireguard.client wireguard-$RESOURCE_PREFIX.conf
}

get_wireguard_config () {
	wireguard-conf
}

deploy_sample_app () {
	get_cluster_config
	oc new-app docker.io/nginxdemos/hello
	oc expose service hello
	until [ $(oc get route --output=name | wc -l) -gt 0 ]; do echo 'Waiting for OpenShift route...'; sleep 5; done
	export ROUTE=$(oc get route --output=json | jq --raw-output '.items[0].spec.host')
	echo "You can open the sample app in your browser at http://$ROUTE"
}

create_sat_link_endpoint () {
	login_ibmcloud
	export SAT_ID=$(ibmcloud sat location get --location "$RESOURCE_PREFIX-location" | grep ID | sed -E 's/ID:\s*//')
	ibmcloud sat endpoint create --dest-hostname $(cd $BASE_DIR/terraform && terraform output -raw ipaddress_onprem_private) --dest-port 80 --dest-type location --location "$SAT_ID" --name Hello-On-Prem-HTTP --source-protocol HTTP
	until ibmcloud sat endpoint ls --location "$SAT_ID" | grep Hello-On-Prem-HTTP ; do echo 'Waiting to satellite link endpoint...'; sleep 30; done
	print_sat_link_hostname
}

print_sat_link_hostname () {
	export SAT_ID=$(ibmcloud sat location get --location "$RESOURCE_PREFIX-location" | grep ID | sed -E 's/ID:\s*//')
	export END_ID=$(ibmcloud sat endpoint ls --location "$SAT_ID" | grep Hello-On-Prem-HTTP  | grep -Eo '((^[A-Za-z0-9_]+\s))' )
	export END_HOSTNAME=$(ibmcloud sat endpoint get --endpoint $(END_ID) --location "$SAT_ID" | grep Address | grep -Eo '(([A-Za-z0-9\-]+\.){7}(com:[0-9]{2,5}))')
	echo "You can reach the on-prem resource at http://$(ibmcloud sat endpoint get --location "$SAT_ID" --endpoint $(ibmcloud sat endpoint ls --location "$SAT_ID" | grep Hello-On-Prem-HTTP | grep -Eo '((^[A-Za-z0-9_]+\s))') | grep Address | grep -Eo '(([A-Za-z0-9\-]+\.){7}(com:[0-9]{2,5}))')/health"
}

all_private_location () {
	login_ibmcloud
	export TF_VAR_CREATE_FLOATING_IP=0 
	apply_terraform
	get_wireguard_config
	attach_host_ready
	assign_controlplane
	assign_controlplane_ready
}

all_private_cluster () {
	login_ibmcloud
	create_cluster
	cluster_in_warning
	assign_workernodes
	cluster_in_normal
}

all_private () {
	all_private_location
	all_private_cluster
	echo "Done!"
}

all_public_location () {
	login_ibmcloud
	export TF_VAR_CREATE_FLOATING_IP=1 
	apply_terraform
	attach_host_ready
	assign_controlplane
	assign_controlplane_ready
	setup_dns_controlplane
}

all_public_cluster () {
	login_ibmcloud
	create_cluster
	cluster_in_warning
	assign_workernodes
	cluster_in_normal
	setup_network_cluster
	configure_cluster_logdna
}

all_public () {
	all_public_location
	all_public_cluster
	echo "Done!"
}
