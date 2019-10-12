region = us-east-2

network:
	aws cloudformation create-stack --stack-name Networking --template-body file://templates/network.yaml \
			--parameters file://env/network.json --region $(region)

sg:
	aws cloudformation create-stack --stack-name SecurityGroups --template-body file://templates/security-groups.yaml \
			--parameters file://env/security-groups.json --region $(region)

application:
	aws cloudformation create-stack --stack-name Application --template-body file://templates/application.yaml \
			--parameters file://env/application.json --capabilities CAPABILITY_NAMED_IAM --region $(region)