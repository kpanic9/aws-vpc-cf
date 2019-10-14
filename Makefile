region = ap-southeast-2

network:
	aws cloudformation create-stack --stack-name Networking --template-body file://templates/network.yaml \
			--parameters file://env/network.json --capabilities CAPABILITY_IAM --region $(region)

sg:
	aws cloudformation create-stack --stack-name SecurityGroups --template-body file://templates/security-groups.yaml \
			--parameters file://env/security-groups.json --region $(region)

cert:
	openssl req -x509 -nodes -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -config ./options.conf
	# aws acm import-certificate --certificate file://cert.pem --private-key file://key.pem --region $(region)
	aws iam upload-server-certificate --server-certificate-name rsvp-certificate --certificate-body file://cert.pem \
			--private-key file://key.pem --region $(region)

application:
	aws cloudformation create-stack --stack-name Application --template-body file://templates/application.yaml \
			--parameters file://env/application.json --capabilities CAPABILITY_NAMED_IAM --region $(region)

cleanup:
	aws cloudformation delete-stack --stack-name Application --region $(region)
	aws cloudformation wait stack-delete-complete --stack-name Application --region $(region)
	aws cloudformation delete-stack --stack-name SecurityGroups --region $(region)
	aws cloudformation wait stack-delete-complete --stack-name SecurityGroups --region $(region)
	aws cloudformation delete-stack --stack-name Networking --region $(region)
	aws cloudformation wait stack-delete-complete --stack-name Networking --region $(region)
	aws iam delete-server-certificate --server-certificate-name rsvp-certificate
