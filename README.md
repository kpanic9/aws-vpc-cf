# AWS-CloudFormation

Goto https://www.freenom.com/ // create an account and login
Check for availability of a sample domain like 'awscftest'
Select the domain and checkout

Go to aws Route 53 Console 
Create a publicaly hosted zone: 'awscftest.tk'
Get the ns record entries and find their ip addresses using, nslookup {dns-name}

On https://www.freenom.com/ Select 'use dns' and 'Use your own dns server'
Insert two ns ip addresses for Route53 Zone found 

Get the ZoneID and domain name

Goto ACM Console and create a certificate using Domain Authentication
    
    
    
## Deploy Application   
     
```bash
sudo apt install make
git clone repo
cd aws-vpc-cf/
make network
make sg
make application
```
     
     
     
     
     

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
   
Lambda@Edge can be used for this task.


