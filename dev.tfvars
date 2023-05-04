region = "us-east-1"
source_bucket_name = "testing_source123"
replica_bucket_name = "replica_source123"


ec2_settings = {
    ami                         = "ami-0cff7528ff583bf9a"
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    key_name                    = "devops"
    vpc_id                      = "vpc-0271c459c930e8e54"
    vpc_security_groups         = ["sg"]
    subnet_id                   = "subnet-011edbedcc5deff88"
    availability_zone           = "us-east-1c"
    root_block_volume_size      = 10
    userdata                    = "echo $SHELL"
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
        name = "ec2"
    }
}