data "aws_iam_policy_document" "s3policy" {
  statement {
    actions = ["s3:GetObject"]

    resources = [
      aws_s3_bucket.website.arn,
      "${aws_s3_bucket.website.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

#############################################

data "aws_iam_policy_document" "policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
        effect = "Allow"
    }
}


############################################
resource "null_resource" "zipdest" {
    provisioner "local-exec" {
        command = "cd ${var.destination} && pip3 install --target ./package -r requirements.txt && cd package && zip -r ../main.zip . -x \"\\*.zip\" && cd .. && zip -gr main.zip main.py"
    }
}
resource "null_resource" "ziphotels" {
    provisioner "local-exec" {
        command = "cd ${var.hotels} && pip3 install --target ./package -r requirements.txt && cd package && zip -r ../main.zip . -x \"\\*.zip\" && cd .. && zip -gr main.zip main.py"
    }
    depends_on = [
      null_resource.zipdest
    ]
}
resource "null_resource" "zipprices" {
    provisioner "local-exec" {
        command = "cd ${var.prices} && pip3 install --target ./package -r requirements.txt && cd package && zip -r ../main.zip . -x \"\\*.zip\" && cd .. && zip -gr main.zip main.py"
    }
    depends_on = [
      null_resource.ziphotels
    ]
}
resource "null_resource" "ziproomprices" {
    provisioner "local-exec" {
        command = "cd ${var.roomprices} && pip3 install --target ./package -r requirements.txt && cd package && zip -r ../main.zip . -x \"\\*.zip\" && cd .. && zip -gr main.zip main.py"
    }
    depends_on = [
      null_resource.zipprices
    ]
}
resource "null_resource" "ziphotelinfo" {
    provisioner "local-exec" {
        command = "cd ${var.hotelinfo} && pip3 install --target ./package -r requirements.txt && cd package && zip -r ../main.zip . -x \"\\*.zip\" && cd .. && zip -gr main.zip main.py"
    }
    depends_on = [
      null_resource.ziproomprices
    ]
}
resource "null_resource" "zipprocessdata" {
    provisioner "local-exec" {
        command = "cd ${var.processdata} && pip3 install --target ./package -r requirements.txt && cd package; zip -r ../main.zip . -x \"\\*.zip\"; cd .. ; zip -gr main.zip main.py"
    }
    depends_on = [
      null_resource.ziphotelinfo
    ]
}

resource "null_resource" "ziphotelsbydestination" {
    provisioner "local-exec" {
        command = "cd ${var.hotelsbydestination} && pip3 install --target ./package -r requirements.txt && cd package; zip -r ../main.zip . -x \"\\*.zip\"; cd .. ; zip -gr main.zip main.py"
    }
    depends_on = [
      null_resource.ziphotelinfo
    ]
}



# data "archive_file" "processData" {
#     depends_on = [
#       null_resource.zipprocessdata
#     ]
#     type = "zip"
#     source_dir = "${path.module}/functions/processData"
#     output_path = "${path.module}/functions/processData/main.zip"
# }

# data "archive_file" "getHotels" {
#   depends_on = [
#     null_resource.ziphotels
#   ]
#   type        = "zip"
#   output_path = "${path.module}/functions/getHotels/main.zip"
#   source_dir = "${path.module}/functions/getHotels"
# }

# data "archive_file" "getDestinations" {
#     depends_on = [
#       null_resource.zipdest
#     ]
#     type = "zip"
#     output_path = "${path.module}/functions/getDestinations/main.zip"
#     source_dir = "${path.module}/functions/getDestinations"
# }

# data "archive_file" "getPrices" {
#     depends_on = [
#       null_resource.zipprices
#     ]
#     type = "zip"
#     output_path = "${path.module}/functions/getPrices/main.zip"
#     source_dir = "${path.module}/functions/getPrices"
# }

# data "archive_file" "getRoomPrices" {
#     depends_on = [
#       null_resource.ziproomprices
#     ]
#     type = "zip"
#     output_path = "${path.module}/functions/getRoomPrices/main.zip"
#     source_dir = "${path.module}/functions/getRoomPrices"
# }

# data "archive_file" "getHotelInfo" {
#     depends_on = [
#       null_resource.ziphotelinfo
#     ]
#     type = "zip"
#     output_path = "${path.module}/functions/getHotelInfo/main.zip"
#     source_dir = "${path.module}/functions/getHotelInfo"
# }
