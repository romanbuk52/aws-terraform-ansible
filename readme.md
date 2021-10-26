Create an AWS user
Use the following steps to create create EC2 instances and installed nginx with custom page.


[pre-begin]\
you need to install aws-cli and authorizate in it
https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html


[example]\
aws_access_key_id = Your_AccessKeyId\
aws_secret_access_key = Your_SecretAccessKey

clone this reposytory in directory .../terraform\
cd /terraform\
Deploy the image with Terraform using:\
terraform init\
terraform apply

You can change the number of instances change variable instance_count in "main" file

I build images on hosts because I collided with the bug that image collected on my computer don't imported in docker on the host(imported without tag and name).

I reworked this terraform from counters on modules system.
