region = "us-east-1"
source_bucket_name = "testing1source123"
replica_bucket_name = "replica1source123"
function_name = "test111"
lambda_execution_role_name = "lambda_execution_role"
sqs_name = "dev-sqs-queue"
sqs_tags = { "Name" = "slds-dev-matillion-sqs"
             "MH or SH" = "SH"
            }

ec2_settings = {
    ami                         = "ami-0cff7528ff583bf9a"
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    key_name                    = "devops"
    vpc_id                      = "vpc-0271c459c930e8e54"
    vpc_security_groups         = ["sg-09c59ba701cf5046b"]
    subnet_id                   = "subnet-011edbedcc5deff88"
    availability_zone           = "us-east-1c"
    root_block_volume_size      = 10
    ports                       = [80, 443, 22]
    cidrs                       = ["0.0.0.0/0"]
    ebs_block_device = [
                        {
                        device_name = "/dev/sdf"
                        volume_type = "gp3"
                        volume_size = 10
                        throughput  = 200
                        encrypted   = true
                        }
                    ]
    tags = {
        "Name" = "slds-dev-matillionserver"
        "MH or SH" = "SH"
    }
}