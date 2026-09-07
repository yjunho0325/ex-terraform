# provider.tf: 클라우드 공급자(AWS/GCP), 비전, 리전 설정
# #########################################################################
# 1. 테라폼 실행 환경 설정 블록
# =========================================================================
terraform {
  required_providers {
    aws = {
      # 프로바이터 라이브러리 다운로드 경로
      source = "hashicorp/aws"

      # 사용할 버전 정의(5.0 이상, 6.0 미만 중 최신버전)
      version = "~> 6.0"
    }

    # required_providers {
    #   google = {
    #     source  = "hashicorp/google"
    #     version = "~> 6.0"
    #   }
    # }

    # 협업을 위한 상태 값 공유 저장소 설정
    # backend "s3" {
    #   bucket         = "bipa17-std08-bucket"
    #   key            = ""
    #   region         = "ap-southeast-2"
    #   dynamodb_table = "std08-terraform-lock-table"
    #   encrypt        = true
    # }
  }
}

provider "aws" {
  region = "ap-southeast-2"
  default_tags {
    tags = {
      Class = "bipa17"
      Owner = "std08"
    }
  }
}
