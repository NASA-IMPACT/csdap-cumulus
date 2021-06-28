TF = ../dotenv terraform

deploy: *.tf *.tfvars
	$(TF) fmt -check
	$(TF) init -reconfigure
	$(TF) apply -auto-approve
	touch deploy

clean:
	rm -f deploy

format:
	$(TF) fmt -check

output:
	$(TF) output
