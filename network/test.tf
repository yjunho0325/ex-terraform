# resource "aws_instance" "this" {
#   count         = 2
#   subnet_id     = "subnet-01c7fd2d256ed8855"
#   ami           = "ami-020728ad6199d7fa0"
#   instance_type = "t3.nano"
#   tags = {
#     Name = "test${count.index + 1}-instance"
#   }
# }

# resource "aws_instance" "this" {
#   for_each      = toset(["logs", "media", "backups"])
#   subnet_id     = "subnet-01c7fd2d256ed8855"
#   ami           = "ami-020728ad6199d7fa0"
#   instance_type = "t3.nano"
#   tags = {
#     Name = "test-${each.key}-instance"
#   }
# }

# resource "aws_instance" "this" {
#   for_each = {
#     "a" = "logs"
#     "b" = "media"
#     "c" = "backups"
#   }
#   subnet_id     = "subnet-01c7fd2d256ed8855"
#   ami           = "ami-020728ad6199d7fa0"
#   instance_type = "t3.nano"
#   tags = {
#     Name = "test-${each.key}-instance" # each.value
#   }
# }

# output "prt_instance" {
#   #   value = aws_instance.this[0].tags
#   #   value = { for k, v in aws_instance.this : k => v.tags["Name"] }
#   value = aws_instance.this["b"].tags
# }
