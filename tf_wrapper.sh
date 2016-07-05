#!/bin/bash 

#Terraform wrapper script for multi-environment deployments using remote state files

display_usage() { 
	echo -e "\e[31m The environment, AWS region and a supported terraform subcommand must all be defined" 
	echo -e "\nUsage:\n$0 [env] [region] [plan|apply|destroy|taint|untaint|show] \n" 
	} 
	if [ $# -lt 3 ] && [ $# -gt 4 ]; then 
		display_usage
		exit 1
	fi 
	if [[ ( $# == "--help") ||  $# == "-h" ]]; then 
		display_usage
		exit 0
	fi 

#Make sure terraform is installed
type terraform >/dev/null 2>&1 || { echo >&2 "Terraform is not installed or in your path, exiting."; exit 1; }

#Define region
REGION=$2
if [ -z "${REGION}" ]; then
        display_usage
	exit 1
elif [ $REGION != "us-east-1" ] && [ $REGION != "us-west-1" ]; then
	echo -e "\e[31m ERROR: Only AWS us-east-1 and us-west-1 are supported regions"
	echo $REGION

	exit 1
fi

#Define specific AWS resource
RESOURCE=$4

#set variables based on environment setting
if [ $1 = "dev" ]; then 
	ENVIRONMENT=dev
	STATE_FILE=terraform-${ENVIRONMENT}.tfstate
	S3_BUCKET=tsm-${ENVIRONMENT}-tf-state-${REGION}
	TFVAR=$ENVIRONMENT/env_${ENVIRONMENT}.tfvars
	SECRETS=$ENVIRONMENT/secrets.tfvars
elif [ $1 = "test" ]; then
	ENVIRONMENT=test
	STATE_FILE=terraform-${ENVIRONMENT}.tfstate
	S3_BUCKET=tsm-${ENVIRONMENT}-tf-state-${REGION}
	TFVAR=$ENVIRONMENT/env_${ENVIRONMENT}.tfvars
	SECRETS=$ENVIRONMENT/secrets.tfvars
elif [ $1 = "prod" ]; then
	ENVIRONMENT=prod
	STATE_FILE=terraform-${ENVIRONMENT}.tfstate
	S3_BUCKET=tsm-${ENVIRONMENT}-tf-state-${REGION}
	TFVAR=$ENVIRONMENT/env_${ENVIRONMENT}.tfvars
	SECRETS=$ENVIRONMENT/secrets.tfvars
else
	echo -e "\e[31m ERROR: Environment must be set to [dev|test|prod]"
        display_usage
        exit 1
fi

remote_config() {
	echo -e "Configuring and pulling terraform remote state from ${S3_BUCKET}.."
	terraform remote config -backend=s3 -backend-config="bucket=${S3_BUCKET}" -backend-config="key=${STATE_FILE}" -backend-config="region=${REGION}" || exit 1

}

plan() {
	echo -e "Running terraform plan for \e[32m ${ENVIRONMENT} \e[0m environment in AWS ${REGION}"
	sleep 2
	terraform plan -var-file=$SECRETS -var-file=$TFVAR -var aws_region=${REGION}
}


apply() {
	start="$(date +%s)"
	echo -e "Running terraform apply for \e[32m ${ENVIRONMENT} \e[0m environment in AWS ${REGION}.."
	sleep 1
	terraform apply -var-file=$SECRETS -var-file=$TFVAR -var aws_region=${REGION}
	end="$(date +%s)"
	echo "================================================================="
        echo -e "\e[32mTerraform ran for $(($end - $start)) seconds"
}

show() {
	echo -e "Running terraform show for \e[32m ${ENVIRONMENT} \e[0m environment in AWS ${REGION}.."
	sleep 2
	terraform show
}


destroy() {
	echo -e "Running terraform destroy for \e[32m ${ENVIRONMENT} \e[0m environment in AWS ${REGION}.."
	terraform destroy -var-file=$SECRETS -var-file=$TFVAR -var aws_region=${REGION}
}

taint() {
	if [ -z "${RESOURCE}" ]; then
		echo "ERROR: the [taint] subcommand requires the AWS resource to be defined"
		terraform --help taint
		exit 1
	fi
	echo -e "Marking terraform resource as tainted for \e[32m ${ENVIRONMENT} \e[0m environment in AWS ${REGION}.."

	terraform taint -var-file=$SECRETS -var-file=$TFVAR -var aws_region=${REGION} $RESOURCE
}

untaint() {
	if [ -z "${RESOURCE}" ]; then
	        echo "ERROR: the [untaint] subcommand requires the AWS resource to be defined"
	        terraform --help untaint
	        exit 1
	fi
	echo -e "Marking terraform resource as tainted for \e[32m  ${ENVIRONMENT} \e[0m environment in AWS ${REGION}.."
	
	terraform untaint -var-file=$SECRETS -var-file=$TFVAR -var aws_region=${REGION} $RESOURCE
}

#Check current env and region in local state, if it exists
LOCAL_STATE=.terraform/terraform.tfstate
if [ -e $LOCAL_STATE ]; then
CURRENT_ENV=`grep Environment ${LOCAL_STATE} |head -1 | cut -d '"' -f 4`
CURRENT_REGION=`grep region ${LOCAL_STATE} |head -1 | cut -d '"' -f 4`

	echo "Local $LOCAL_STATE file exists.."
	if [ $CURRENT_ENV = $1 ] && [ $CURRENT_REGION = $2 ]; then
		echo -e "Local $LOCAL_STATE file is set to the \e[32m ${CURRENT_ENV} \e[0m environment and \e[32m ${CURRENT_REGION} \e[0m, proceeding.."
	else
		echo -e "Local $LOCAL_STATE file is not set to the environment or region specified, purging & pulling remote state.."
		rm -f ${LOCAL_STATE}
	fi
fi

#Always set/pull tf remote state
remote_config

if [ $3 = "plan" ]; then
	plan
elif [ $3 = "apply" ]; then
	apply
elif [ $3 = "taint" ]; then
        taint
elif [ $3 = "untaint" ]; then
        untaint
elif [ $3 = "show" ]; then
        show
elif [ $3 = "destroy" ]; then
 	destroy
else
	echo -e "\e[31m ERROR: [plan|apply|destroy|taint|untaint|show] are the only subcommands supported"
        display_usage
        exit 1
fi

