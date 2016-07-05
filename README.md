# Terraform multi-environment wrapper

## Overview

This project is a small shell wrapper script to handle multi-env and multi-region terraform deployments in the AWS cloud.

## Dependencies

* An S3 bucket for each environment must be in place. 

### Usage
The environment, AWS region and terraform subcommand must be defined in the order below..

```sh
./tf_wrapper.sh [env] [region] [plan|apply|destroy|show|taint|untaint]
```

#### Deploy environments 

##### Example1 - Deploying dev environment in the AWS us-east-1 region

The 'plan' option will show what changes will be made and validates syntax...

```sh
$ ./tf_wrapper.sh dev us-east-1 plan

```

The 'apply' option will apply the setting shown during the plan

```sh
$ ./tf_wrapper.sh dev us-east-1 apply

```
The 'destroy' option will tear down the resources managed by this terraform project.

```sh
$ ./tf_wrapper.sh dev us-east-1 destroy

```
##### Example2 - Deploying test environment in the AWS us-west-1 region

```sh
$ ./tf_wrapper.sh test us-west-1 plan

```

```sh
$ ./tf_wrapper.sh test us-west-1 apply

```
#### Using *show* subcommand

The 'show' option reads and outputs a terraform state file in a human-readable form.

```sh
$ ./tf_wrapper.sh test us-west-1 show

```

#### Using *taint/untaint* subcommand

The 'taint' and 'untaint' options manually marks or unmarks a resource to be destroyed and recreated on the next plan/apply. The resource name can be found from the 'show' subcommand option.

```sh
$ ./tf_wrapper.sh test us-west-1 taint <aws_resource>
$ ./tf_wrapper.sh test us-west-1 untaint <aws_resource>

```

## Limitations
* The configuration was developed and tested with Terraform v0.6.16.

