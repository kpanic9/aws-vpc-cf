# AWS-CloudFormation-VPC    
     
Note: App stack is using a self signed certificate      
	  Instances can be accessed from Systems Manager

ToDO:   
1. Add NACLs to add more fine grained controlled traffic in subnets
2. Use a S3 bucket to collect ALB Access Logs
     
     

## Deploy Application   
     
```bash    
sudo apt install make -y
git clone git@github.com:kpanic9/aws-vpc-cf.git
cd aws-vpc-cf/
make network
make sg
make cert
# Update the 'CertificateArn' paremeter in env/application.json file form the output of the above target
# For some reason imported acm cert did not work on my account, therefore I had to go with the iam server certificates
make application
```
     
For accessing the webpage, get the loadbalancer dns name and goto: https://{load-balancer-dns-name}/    
    
    
### Clean up    
     
```bash
make cleanup
```
   
    
    
### Steps for using public domain   
   
1. Goto a public domain registry and register domain (Or we can do it in Route53 Console as aws sells domain names)   
2. Create Route53 Zone for that domain   
3. Get the NS record values for that zone and update Domain Registry   
4. Update the 'R53PublicZoneId' paremeters in env/application.json file   
5. Update 'AlbDnsRecord' (Eg: app.awscftest.com) paremeters in env/application.json file     
6. Goto ACM Console and create a certificate using Domain Authentication   
7. Update the 'CertificateArn' paremeter in env/application.json file     
8. Uncomment the code in templates/application.yaml from line number 249    
       

    
     

     
     
     
     
      
## TODO - Theory    
   
   
### Provide access into the stack for operations staff who might need to inspect an instance directly  
    
1. Create a specific tag for the instances   
{Tag-Name}: {Tag-Value}     

2. Attach AmazonEC2RoleforSSM to the instance role   

3. Install ssm agent on ec2 instance as a part of launch config    

4. Create an IAM Group 'StackSSHAccess'    

5. Create and attach below policy to the group 'StackSSHAccess'    
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:instance/*"
            ],
            "Condition": {
                "StringLike": {
                    "ssm:resourceTag/{Tag-Name}": [
                        "{Tag-Value}"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeSessions",
                "ssm:GetConnectionStatus",
                "ssm:DescribeInstanceProperties",
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:CreateDocument",
                "ssm:UpdateDocument",
                "ssm:GetDocument"
            ],
            "Resource": "arn:aws:ssm:ap-southeast-2:{account-id}:document/SSM-SessionManagerRunShell"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:TerminateSession"
            ],
            "Resource": [
                "arn:aws:ssm:*:*:session/${aws:username}-*"
            ]
        }
    ]
}
```
    
6. Add the user to 'StackSSHAccess' group    
    
    
   
    
### Make server access and error logs available in CloudWatch Logs    
    
1. Attach the below iam policy to the instance role.   
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
 ]
}
```
    
2. Add the below script to the userdata    
```bash
cat > ./awslogs-config <<EOF
[general]
state_file = /var/awslogs/state/agent-state
 
[/var/log/nginx/access.log]
file = /var/log/nginx/access.log
log_group_name = /var/log/nginx/access.log
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S

[/var/log/nginx/error.log]
file = /var/log/nginx/error.log
log_group_name = /var/log/nginx/error.log
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S
EOF

curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
apt install python2.7 -y
python2.7 awslogs-agent-setup.py -n --region ap-southeast-2 -c ./awslogs-config
```
    
    
    
    
### Serve via a CloudFront distribution   
    
CloudFront ---> Create Distribution   
Origin Domain Name: Select the elb   
Enable logging and add s3 bucket with log prefix   
Set the distribution state to enabled and create the distribution   

Then from the Route53 or DNS server we have to create a CNAME record pointing to the Domain Name of the cloudfront distribution   
   
   
   
   
   
### Use Lambda to handle error pages    
     
A cloudfront distribution and Lambda@Edge can be used for this task. It allows to execute Lambda functions in response to HTTP errors that Amazon CloudFront receives from the distribution origin origin.
First we need to create the lambda function that is invoked when Cloudfront distribution receives a specific error code.
Then we have to update lambda function trigger to invoke the Lambda function when cloudfront distribution receives (Origin Response Event) the error code from the lambda console enabling lambda function replication. 






