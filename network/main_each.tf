# main.tf: 리소스 정의 및 모듈 호출
# ##########################################################################################
# 1. VPC 생성
# ==========================================================================================
resource "aws_vpc" "std08_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.tag_header}vpc"
  }
}
# ##########################################################################################
# 2. Public Subnet 생성
# ==========================================================================================
resource "aws_subnet" "std08_public_subnet" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.std08_vpc.id
  cidr_block        = var.subnet_cidr[0][each.key]
  availability_zone = each.key

  # Public Subnet 설정: 퍼블릭 IP 자동 할당, DNS A 레코드 자동 생성
  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true

  tags = {
    Name = "${local.tag_header}public${split("-", each.key)[length(split("-", each.key)) - 1]}-subnet"
  }
}

# ##########################################################################################
# 3. Private Subnet 생성
# ==========================================================================================
resource "aws_subnet" "std08_private_subnet" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.std08_vpc.id
  cidr_block        = var.subnet_cidr[1][each.key]
  availability_zone = each.key

  tags = {
    Name = "${local.tag_header}private${split("-", each.key)[length(split("-", each.key)) - 1]}-subnet"
  }
}

# ##########################################################################################
# 4. Gateway 생성
# ==========================================================================================
# 4.1 Internet Gateway 생성
resource "aws_internet_gateway" "std08_igw" {
  vpc_id = aws_vpc.std08_vpc.id
  tags = {
    Name = "${local.tag_header}igw"
  }
}

# 4.2 NAT Gateway 생성을 위한 Elastic IP 생성
resource "aws_eip" "std08_nat_eip" {
  domain = "vpc" # VPC용 EIP 생성, eip의 사용범위를 VPC로 제한
  tags = {
    Name = "${local.tag_header}nat-eip"
  }
}

# 4.3 NAT Gateway 생성
resource "aws_nat_gateway" "std08_nat_gw" {
  allocation_id = aws_eip.std08_nat_eip.id
  subnet_id     = aws_subnet.std08_public_subnet[local.azs[0]].id
  depends_on    = [aws_internet_gateway.std08_igw]
  tags = {
    Name = "${local.tag_header}nat-gw"
  }
}

# ##########################################################################################
# 5. Route Table 생성
# ==========================================================================================
# 5.1 생성
resource "aws_route_table" "std08_public_rt" {
  vpc_id = aws_vpc.std08_vpc.id
  tags = {
    Name = "${local.tag_header}public-rt"
  }
}
resource "aws_route_table" "std08_private_rt" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.std08_vpc.id
  tags = {
    Name = "${local.tag_header}private${split("-", each.key)[length(split("-", each.key)) - 1]}-rt"
  }
}

# 5.2 서브넷 연결
resource "aws_route_table_association" "std08_public_rt_assoc" {
  for_each       = toset(local.azs)
  subnet_id      = aws_subnet.std08_public_subnet[each.key].id
  route_table_id = aws_route_table.std08_public_rt.id
}
resource "aws_route_table_association" "std08_private_rt_assoc" {
  for_each       = toset(local.azs)
  subnet_id      = aws_subnet.std08_private_subnet[each.key].id
  route_table_id = aws_route_table.std08_private_rt[each.key].id
}

# 5.3 라우팅
resource "aws_route" "std08_public_rt_route" {
  route_table_id         = aws_route_table.std08_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.std08_igw.id
}
resource "aws_route" "std08_private_rt_route" {
  for_each               = toset(local.azs)
  route_table_id         = aws_route_table.std08_private_rt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.std08_nat_gw.id
}

# ##########################################################################################
# 6. Security Group 생성
# ==========================================================================================
# SSH 접속용 Security Group 생성
resource "aws_security_group" "std08_ssh_sg" {
  name        = "${local.tag_header}ssh-sg"
  description = "Security Group for SSH access"
  vpc_id      = aws_vpc.std08_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜 허용
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}ssh-sg"
  }
}

# MySQL 접속용 Security Group 생성
resource "aws_security_group" "std08_mysql_sg" {
  name        = "${local.tag_header}mysql-sg"
  description = "Security Group for MySQL access"
  vpc_id      = aws_vpc.std08_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}mysql-sg"
  }
}

# fastapi 접속용 Security Group 생성
resource "aws_security_group" "std08_fastapi_sg" {
  name        = "${local.tag_header}fastapi-sg"
  description = "Security Group for FastAPI access"
  vpc_id      = aws_vpc.std08_vpc.id
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}fastapi-sg"
  }
}

# Web 보안그룹(외부 ALB용)
resource "aws_security_group" "std08_external_alb_sg" {
  name        = "${local.tag_header}external-alb-sg"
  description = "Security Group for web access"
  vpc_id      = aws_vpc.std08_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}external-alb-sg"
  }
}

# ================ 프라이빗 웹 인스턴스용 보안그룹 ============================================
resource "aws_security_group" "std08_internal_alb_sg" {
  name        = "${local.tag_header}internal-alb-sg"
  description = "Security Group for private web instances"
  vpc_id      = aws_vpc.std08_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}internal-alb-sg"
  }
}

# 보안그룹 규칙 추가: 외부 ALB에서 내부 ALB로의 트래픽 허용
resource "aws_security_group_rule" "std08_internal_alb_rule" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  # 소스로 어떤 보안그룹을 추가할지 추가할 보안그룹의 ID 지정
  source_security_group_id = aws_security_group.std08_external_alb_sg.id
  # 규칙을 추가할 보안그룹의 ID
  security_group_id = aws_security_group.std08_internal_alb_sg.id
}

# ================ EKS NodePort 보안그룹 ===============================================
resource "aws_security_group" "std08_eks_nodeport_sg" {
  name        = "${local.tag_header}eks-nodeport-sg"
  description = "Security Group for EKS NodePort access"
  vpc_id      = aws_vpc.std08_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}eks-nodeport-sg"
  }
}

# 보안그룹 규칙 추가: EKS NodePort에서 External ALB로의 트래픽 허용
resource "aws_security_group_rule" "std08_eks_nodeport_rule" {
  type      = "ingress"
  from_port = 30000
  to_port   = 32767
  protocol  = "tcp"
  # 소스로 어떤 보안그룹을 추가할지 추가할 보안그룹의 ID 지정
  source_security_group_id = aws_security_group.std08_external_alb_sg.id
  # 규칙을 추가할 보안그룹의 ID
  security_group_id = aws_security_group.std08_eks_nodeport_sg.id
}

# ##########################################################################################
# 테라폼 = 선언형 언어, IF문이 없음
# IF문을 대체하는 3항 연산자를 통해 간단한 제어만 가능
# [일반 3항 연산자]조건 ? 조건이 참일 때의 값 : 조건이 거짓일 때의 값
# [다중 3항 연산자]조건1 ? 조건1이 참일 때의 값 : 조건2 ? 조건2가 참일 때의 값 : 조건2가 거짓일 때의 값
# ==========================================================================================
locals {
  instance_chk = true
}
resource "aws_instance" "std08_instance" {
  count         = local.instance_chk ? 1 : 0
  ami           = "ami-020728ad6199d7fa0"
  subnet_id     = aws_subnet.std08_public_subnet[local.azs[0]].id
  instance_type = "t3.micro"

  tags = {
    Name = "std08-instance-${count.index + 1}"
  }
}

# -------------------------------------------------------------------------------------------
# 중첩 삼항 연산자
locals {
  instance_type = "default" # "nano, micro, small"
}
resource "aws_instance" "std08_ins" {
  ami       = "ami-020728ad6199d7fa0"
  subnet_id = aws_subnet.std08_public_subnet[local.azs[0]].id
  instance_type = local.instance_type == "default" ? "t3.nano" : (
  local.instance_type == "micro" ? "t3.micro" : "t3.small")

  tags = {
    Name = "std08-ins"
  }
}

# ##########################################################################################
# 문자열 함수
output "zfunc_string_upper" {
  value = upper("abcd") # 대문자 변환
}
output "zfunc_string_lower" {
  value = lower("aBCd") # 소문자 변환
}
output "zfunc_string_replace" {
  value = replace("abcdb", "b", "K") # 찾은 문자열 모두 치환
}

# 문자열 나누기
# 전체 문자열에서 특정 문자를 기준으로 나누어 리스트로 변환
output "zfunc_string_split" {
  value = split("-", "ap-southeast-2a")[length(split("-", "ap-southeast-2a")) - 1]
}
output "zfunc_string_join" {
  value = join("*", split("-", "ap-southeast-2a"))
}

# for 표현식
output "for" {
  value = [for num in [1, 2, 5, 80, 123, 77] : num * 3 if num % 2 == 0]
}
