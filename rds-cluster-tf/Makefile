deploy: *.tf *.tfvars
	../dotenv terraform init -reconfigure
	../dotenv terraform apply -auto-approve
	touch deploy

output:
	../dotenv terraform output
