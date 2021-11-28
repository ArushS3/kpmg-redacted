### Challenge-1 ###

I created a three tier environment in Azure using terraform consisting of the following resources:-
1. Availability Sets(web and app)
2. Virtual Machines(webserver and app server)
3. Azure Sql Database(Appserver can connect to database and database can connect to appserver but database cannot connect to webserver)
4. Network Security Group(for each subnet)
5. Virtual Network with three subnets(web,app and db)

## Terraform configuration

It has two files:-
1. variables.tf- contains the declaration for the variables
2. main.tf- contains all the resources to be provisioned
 
## deploy

Note:- Please specify your tenant id of your azure account in the main.tf file at line 13 "tenant_id = "XXXX-XXX-XXXX" before running the terraform commands as I restricted it after testing the resources.

## Terraform commands to deploy

1. terraform init- to initialise the azurerm providers
2. terraform plan - to generate your execution plan
3. terraform validate - to validate whether your config is valid.
4. terraform apply - to provision your resources

### Challenge-2 ###
Code:- 

curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq

 # output for challenge-two are uploaded in a seperate document in mail #

### Challenge 3 ###
The code is inside the technical-challenge-3 folder,goes by the name of nested js

#  Check whether node is installed on your machine.
1. node -v

# Run below command inside technical-challenge-3 folder
2. node nested.js
