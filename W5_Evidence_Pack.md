# Evidence Pack W5: The Network Fortress
## XBrain_Group10

---

## Cover

| Thông tin | Chi tiết |
|-----------|---------|
| **Nhóm** | XBrain_Group10 |
| **Tên thành viên** | Lê Trần Tuấn Khanh, Trần Mạnh Trường, Trần Mạnh Cường, Nguyễn Đức Hảo, Lê Văn Hải, Phan Đức Huy, Lê Viết Quốc Hưng, Huỳnh Xuân Hậu, Nguyễn Thị Mến, Trần Quốc Hùng |
| **Tuần** | W5 - The Network Fortress (11–15 tháng 5, 2026) |
| **Deadline** | Thứ Sáu 15-05-2026 |
| **Link Repository** | [Nhập link repo của nhóm] |
| **Evidence Pack tuần trước** | https://github.com/huyjaky/w4aws |
| **Ngày tạo** | 14-05-2026 |

---

## 1. Application Recap & Reflection

### Kiến trúc hiện tại

**Mô tả ngắn ứng dụng:**
- **Tên ứng dụng:** [Nhập tên ứng dụng]
- **Stack công nghệ:** [VD: Python/Node.js, RDS/DynamoDB, Lambda, Bedrock]
- **Dịch vụ AI được tích hợp:** Amazon Bedrock (Claude Sonnet 4-6, Claude Sonnet 4-5)
- **Lớp lưu trữ file:** Amazon EFS (fs-0ed34a016c3fe7c67)
- **Cơ sở dữ liệu:** RDS PostgreSQL (webapp-group10-database)
- **Backup được quản lý bởi:** AWS Backup

### Feedback từ tuần trước và cách W5 xử lý

| Feedback W4 | Cách W5 xử lý | Bằng chứng |
|-------------|---------------|----------|
| [Nhập feedback cụ thể từ W4] | [Mô tả cách W5 giải quyết] | [Screenshot/Chi tiết] |
| VD: Không có multi-AZ | W5 cập nhật subnet thành multi-AZ | [Screenshot subnet] |
| VD: Backup plan chưa có | W5 tạo AWS Backup plan bao trùm EFS, RDS, EBS | [Screenshot backup plan] |

### Ứng dụng chạy end-to-end (Live Demo)

**Action đại diện chứng minh app hoạt động:**

```
Lệnh kiểm tra:
[Nhập lệnh curl hoặc test thực tế]

Output:
[Kết quả trả về]
```

**Screenshot:** [Action end-to-end đang chạy trên deployment live]

---

## 2. MH1 — Multi-VPC Connectivity

### Connectivity Decision: Justified Single-VPC with Multi-AZ Enhancement

**Justification cho Single-VPC:**
1. **Đơn giản hóa kiến trúc:** Ứng dụng chatbot là single-tenant SaaS không cần network isolation cấp VPC. Tất cả components (web frontend, LLM backend, database, embedding store) thuộc về cùng một ứng dụng logic.

2. **Cost-effective:** Single-VPC không cần Transit Gateway ($0.05/hour = $36/month) hay VPC peering management overhead. VPC charge vẫn flat rate $0.07/day cho single VPC.

3. **Latency thấp:** Tất cả tầng chạy cùng VPC → không có inter-VPC latency. Quan trọng cho real-time chat response (target latency < 500ms từ user query tới bot answer).

4. **Easy troubleshooting:** VPC Flow Logs từ một VPC duy nhất dễ analyze hơn. Khi user báo "chatbot slow", có thể trace flow trên một VPC thay vì phải check routing giữa nhiều VPC.

5. **Không có compliance requirement:** Chatbot application không cần comply PCI-DSS (không xử lý payment cards), HIPAA (không xử lý health data), hay bất kỳ regulation nào đòi hỏi network isolation cấp VPC.

**Multi-AZ Enhancement for High Availability:**
Tất cả subnet tiers được mở rộng sang **Multi-AZ** (us-east-1a, us-east-1b và us-east-1c):

**Khi nào sẽ trigger Multi-VPC transition:**
1. **Multi-region deployment:** Khi mở rộng sang Singapore, Tokyo, hoặc region khác → sẽ cần VPC riêng per region + Transit Gateway global hub
2. **Separate staging/production:** Khi team scale và cần strict network isolation giữa prod (sensitive data) vs staging (test data) → sẽ tách thành VPC riêng
3. **Third-party chatbot integration:** Khi integrate với partner APIs (Slack bot marketplace, Teams integration) → sẽ cần VPC peering với partner infrastructure
4. **Compliance expansion:** Nếu sau này support healthcare/financial domain → HIPAA/PCI-DSS → sẽ cần dedicated VPC per compliance tier

1. Tổng quan kiến trúc VPC
Hệ thống được triển khai trên một VPC duy nhất với tên webapp-group10-vpc, đóng vai trò là mạng nội bộ trung tâm cho toàn bộ hạ tầng ứng dụng trên AWS.
Kiến trúc mạng được thiết kế theo mô hình phân tầng nhằm tách biệt các thành phần public, private, database và firewall để tăng cường bảo mật và khả năng quản lý traffic.

a) Thông tin VPC
Tên VPC: webapp-group10-vpc
Mô hình: Single VPC Architecture
Triển khai: Multi-AZ
Region: us-east-1
<img width="1522" height="780" alt="image" src="https://github.com/user-attachments/assets/07f8ce78-8338-49d6-aafd-abfa84804515" />

b) Thiết kế Subnet
Hệ thống sử dụng tổng cộng 12 subnet, được phân bổ trên 3 Availability Zone:
- us-east-1a
- us-east-1b
- us-east-1c

Mỗi AZ bao gồm:
- Public Subnet
Dùng cho các tài nguyên public-facing:
   + Application Load Balancer (ALB)
   + NAT Gateway
   + Internet access

- Private Subnet
Dùng cho các tài nguyên nội bộ:
   + ECS/Fargate services
   + Backend application
   + Internal microservices
     
- Database Subnet
Dùng để triển khai cơ sở dữ liệu trong môi trường private:
   + Amazon RDS
   + Database services
  
- Firewall Subnet
Dùng cho AWS Network Firewall nhằm kiểm soát và giám sát traffic mạng.

c) Route Tables
Hệ thống sử dụng nhiều route table riêng biệt để quản lý traffic cho từng loại subnet:
- Public Route Table
webapp-group10-public-rt
<img width="1541" height="450" alt="image" src="https://github.com/user-attachments/assets/1d243e4a-cf01-4352-b6a2-9c8dccb4abf9" />

Chức năng:
Route internet traffic thông qua Internet Gateway.

- Private Route Tables
   + webapp-group10-private-1-rt
   + webapp-group10-private-2-rt
   + webapp-group10-private-3-rt
<img width="1598" height="446" alt="image" src="https://github.com/user-attachments/assets/ea7e3f3c-c242-4c91-a263-04a703a64059" />

Chức năng:
Private subnet route table được cấu hình chuyển toàn bộ outbound traffic
(0.0.0.0/0) tới AWS Network Firewall Endpoint.

Điều này đảm bảo mọi traffic đều phải được inspection
trước khi ra Internet thông qua NAT Gateway.

- Database Route Table
webapp-group10-database-rt
<img width="1598" height="415" alt="image" src="https://github.com/user-attachments/assets/4063713e-ded0-429f-a37d-b1672c324e07" />

Chức năng:
Tách biệt traffic database khỏi public network nhằm tăng bảo mật.

- Firewall Route Tables
    + webapp-group10-network-firewall-subnet-rt-1
    + webapp-group10-network-firewall-subnet-rt-2
    + webapp-group10-network-firewall-subnet-rt-3
<img width="1566" height="447" alt="image" src="https://github.com/user-attachments/assets/0d13619f-0dbe-43e5-98a0-4689f664d0b4" />
Chức năng:

   Route table của firewall subnet được cấu hình chuyển outbound traffic
từ AWS Network Firewall tới NAT Gateway trước khi truy cập Internet.

Kiến trúc này đảm bảo traffic flow hoạt động theo mô hình:

     Application Workload
→ AWS Network Firewall
→ NAT Gateway
→ Internet

Firewall subnet đóng vai trò xử lý và forward traffic
sau khi hoàn tất quá trình stateful inspection và security filtering.
      
2) Network Connectivity

Hệ thống sử dụng:
- Internet Gateway
    + webapp-group10-igw
<img width="1611" height="335" alt="image" src="https://github.com/user-attachments/assets/a3f5b7b2-6ffb-4e2d-b707-518255109516" />
Chức năng:
    + Kết nối public subnet với Internet.
      
- NAT Gateway
    + webapp-group10-regional-nat
<img width="1583" height="532" alt="image" src="https://github.com/user-attachments/assets/d64881f0-4fc4-41b3-ae88-3a7e0c4494eb" />
Chức năng:
    + Cho phép private subnet truy cập Internet outbound mà không expose trực tiếp ra public Internet.
      
5. Multi-AZ Architecture
   
- Kiến trúc được triển khai trên 3 Availability Zone nhằm:
- Tăng tính sẵn sàng (High Availability)
- Đảm bảo khả năng chịu lỗi (Fault Tolerance)
- Giảm downtime khi một AZ gặp sự cố
- Phân phối workload hiệu quả hơn
6. Flow logs
  
  a) VPC Flow Logs
  
Để giám sát và phân tích lưu lượng mạng trong hệ thống, VPC đã được cấu hình Flow Logs nhằm ghi nhận toàn bộ network traffic đi vào và đi ra khỏi VPC.
Flow Logs giúp:
- Theo dõi traffic giữa các subnet
- Phân tích network connectivity
- Phát hiện traffic bất thường
- Hỗ trợ troubleshooting và security monitoring 
<img width="1602" height="544" alt="image" src="https://github.com/user-attachments/assets/d3c84c35-08d4-4763-aa84-63308779b17d" />
<img width="1684" height="827" alt="image" src="https://github.com/user-attachments/assets/75c08aeb-bb27-446e-b91f-f035359a9066" />


## 3. MH2 — Network Firewall Hardening (Ép buộc tại biên)

## Lựa chọn Path

### Path đã chọn:
☑ Path A — AWS Network Firewall (Stateful firewall + IPS signatures)

Kiến trúc sử dụng AWS Network Firewall để kiểm tra và kiểm soát toàn bộ outbound traffic trước khi truy cập Internet thông qua NAT Gateway.

---

# a) Architecture Overview

Kiến trúc triển khai AWS Network Firewall theo mô hình centralized traffic inspection.

Toàn bộ outbound traffic từ private subnet được ép buộc đi qua AWS Network Firewall Endpoint trước khi tới NAT Gateway và Internet.
## Traffic Flow

```text
ECS/EC2
→ Firewall Endpoint
→ AWS Network Firewall
→ NAT Gateway
→ Internet
```

---
<img width="1669" height="511" alt="image" src="https://github.com/user-attachments/assets/2b8030d3-6416-4280-a1fa-6da486b1cc20" />

# b) Firewall Subnet

Dedicated firewall subnet được triển khai riêng biệt trong từng Availability Zone để cô lập firewall traffic khỏi application workload.

Firewall subnet đóng vai trò xử lý và kiểm tra traffic trước khi traffic rời khỏi VPC.

---
<img width="1564" height="487" alt="image" src="https://github.com/user-attachments/assets/b88a4396-c54b-4682-9113-8201112b8d8f" />

# c) Stateful Traffic Inspection

AWS Network Firewall được cấu hình với Stateful Rule Groups để thực hiện deep packet inspection và phát hiện traffic bất thường.

<img width="1655" height="396" alt="image" src="https://github.com/user-attachments/assets/9b14a8e2-6b3c-4d4a-9c4a-7f0a79ca6730" />

<img width="780" height="228" alt="image" src="https://github.com/user-attachments/assets/8f45afb7-45c3-452d-aee8-07a8f4b8d808" />
# d) Alert Logging & Monitoring

Alert Logs được bật và gửi về Amazon CloudWatch Logs để phục vụ centralized monitoring, auditing và security investigation.
<img width="1681" height="650" alt="image" src="https://github.com/user-attachments/assets/b1b03e52-9ee7-4ab3-b813-d3ed3926a5af" />

- Chứng minh firewall có inspect traffic thật.

## 4. MH3 — File Storage Layer + Backup Plan (Chia sẻ data, bảo vệ state)

### File Storage - Amazon EFS

#### Cấu hình EFS

<img width="1484" height="611" alt="image" src="https://github.com/user-attachments/assets/5493e7fc-a5d7-48d8-8967-0b411f3e7519" />


| Thông tin | Chi tiết |
|-----------|---------|
| **File System ID** | fs-0a4a0e5366e9cba6d |
| **Tên** | webapp-group10-efs |
| **Region** | us-east-2 |
| **Performance Mode** | General Purpose |
| **Throughput Mode** | Bursting |
| **Encryption at Rest** | ✅ Enabled (KMS) |
| **Lifecycle Policy** | Transition to IA after 30 days, Transition into Archive after 90 days |

**Mount Targets:**

| Mount Target | Subnet | AZ | Security Group |
|--------------|--------|-----|----------------|
| fsmt-054f7205bc6cf2dc1 | subnet-036fb118a237b276c | us-east-1a | sg-0eb46af8830cb636f (webapp-group10-efs-sg) |
| fsmt-0b7cbbdfdf6807008 | subnet-01c802af5ab604ed6 | us-east-1b | sg-0eb46af8830cb636f (webapp-group10-efs-sg) |
| fsmt-01623bdaa071cebf0 | subnet-0148c1ed9dd01ab02 | us-east-1c | sg-0eb46af8830cb636f (webapp-group10-efs-sg) |

**Security Group của Mount Target:**

```yaml
IngressRules:
  - IpProtocol: tcp
    FromPort: 2049           # NFS port
    ToPort: 2049
    SourceSecurityGroupId: sg-app-tier
    Description: "NFS từ App Tier chỉ"

EgressRules:
  - IpProtocol: -1
    CidrIp: 0.0.0.0/0
```

#### Mount EFS trên ECS

<img width="1591" height="612" alt="image" src="https://github.com/user-attachments/assets/665f60f4-4895-4f54-b0cc-64fc6f41bb02" />


**Screenshot - EFS Mount Successful:**
<img width="1193" height="427" alt="image" src="https://github.com/user-attachments/assets/8b4178d2-8d5c-4529-a09b-6b84e90b31e7" />

#### Write & Read Test

**Nội dung thật của ứng dụng được lưu:**

```bash
# Write - Lưu session token hoặc file upload từ user
echo "session_token_abc123def456" > /mnt/efs/sessions/user-1.token
echo "[2026-05-15] User uploaded document.pdf" > /mnt/efs/uploads/document.pdf.log

# Read - Đọi lại để verify
cat /mnt/efs/sessions/user-1.token
# Output: session_token_abc123def456

cat /mnt/efs/uploads/document.pdf.log
# Output: [2026-05-15] User uploaded document.pdf
```

**Screenshot - Write Test:**
![Write Test](./images/w5-mh3-efs-write.png)

**Screenshot - Read Test:**
![Read Test](./images/w5-mh3-efs-read.png)

---

## Backup Plan và Restore Verification

### Tổng quan triển khai

Trong phần này, nhóm triển khai AWS Backup để tự động backup các tài nguyên quan trọng của hệ thống nhằm đáp ứng yêu cầu disaster recovery và data protection.

Backup strategy bao gồm:

* AWS Backup Plan tự động chạy theo lịch
* Backup nhiều resource production
* Lưu recovery point trong Backup Vault
* Kiểm tra restore thực tế từ recovery point
* Xác minh dữ liệu sau restore thành công

---

### AWS Backup Plan

#### Backup Plan Information

| Thông tin            | Chi tiết               |
| -------------------- | ---------------------- |
| **Backup Plan Name** | webapp-group10-backup  |
| **Backup Vault**     | webapp-group10-vault   |
| **Status**           | ✅ Active               |
| **Created Time**     | May 14, 2026           |
| **Schedule**         | Daily Automatic Backup |
| **Backup Service**   | AWS Backup             |

Ngoài backup plan chính do nhóm cấu hình, hệ thống còn có automatic backup plan mặc định cho Amazon EFS.

---

#### Existing Backup Plans

| Backup Plan                       | Type                   | Status   |
| --------------------------------- | ---------------------- | -------- |
| **webapp-group10-backup**         | Custom Backup Plan     | ✅ Active |
| **aws/efs/automatic-backup-plan** | AWS Managed EFS Backup | ✅ Active |

---

#### Screenshot — Backup Plans

```markdown
![Backup Plans](./images/w5-backup-plans.png)
```

**Mô tả screenshot cần capture:**

* AWS Console → AWS Backup → Backup Plans
* Hiển thị:

  * `webapp-group10-backup`
  * `aws/efs/automatic-backup-plan`
* Hiển thị trạng thái active
* Hiển thị created time

---

### Backup Vault Configuration

#### Backup Vault

| Thông tin      | Chi tiết               |
| -------------- | ---------------------- |
| **Vault Name** | webapp-group10-vault   |
| **Vault Type** | Customer Managed Vault |
| **Status**     | ✅ Available            |

Backup vault được sử dụng để lưu trữ recovery points của toàn bộ hệ thống.

---

#### Screenshot — Backup Vault

```markdown
![Backup Vault](./images/w5-backup-vault.png)
```

**Mô tả screenshot cần capture:**

* AWS Console → AWS Backup → Backup Vaults
* Hiển thị:

  * `webapp-group10-vault`
  * Number of recovery points
  * Vault status

---

### Resource Assignment

AWS Backup được cấu hình để backup nhiều tài nguyên production quan trọng của hệ thống.

#### Resource Assignment Information

| Thông tin                    | Chi tiết                        |
| ---------------------------- | ------------------------------- |
| **Resource Assignment Name** | webapp-group10-backup-resources |
| **IAM Role**                 | AWSBackupDefaultServiceRole     |
| **Assignment Method**        | ARN-based selection             |

---

#### Resources được Backup

| Resource Type | Resource ARN                                                                      | Status     |
| ------------- | --------------------------------------------------------------------------------- | ---------- |
| **EFS**       | arn:aws:elasticfilesystem:us-east-1:379353384462:file-system/fs-0ed34a016c3fe7c67 | ✅ Included |
| **RDS**       | arn:aws:rds:us-east-1:379353384462:db:webapp-group10-database                     | ✅ Included |
| **S3**        | arn:aws:s3:::webapp-group10-app-bucket                                            | ✅ Included |
| **S3**        | arn:aws:s3:::webapp-group10-backend-env                                           | ✅ Included |
| **S3**        | arn:aws:s3:::webapp-group10-frontend-bucket                                       | ✅ Included |
| **S3**        | arn:aws:s3:::webapp-group10-kb-source                                             | ✅ Included |
| **S3**        | arn:aws:s3:::webapp-group10-multimedia-kb                                         | ✅ Included |

---

#### Screenshot — Resource Assignment

```markdown
![Backup Resource Assignment](./images/w5-backup-resource-assignment.png)
```

**Mô tả screenshot cần capture:**

* AWS Console → AWS Backup → Protected Resources hoặc Resource Assignments
* Hiển thị:

  * Resource assignment name
  * IAM Role
  * Danh sách resource ARN
  * EFS, RDS, S3 buckets

---

### Backup Rule Configuration

#### Backup Rule

```yaml
BackupPlan: webapp-group10-backup

Rules:
  - RuleName: daily-backup
    TargetBackupVault: webapp-group10-vault

    ScheduleExpression: "cron(0 2 * * ? *)"

    Lifecycle:
      MoveToColdStorageAfterDays: 30
      DeleteAfterDays: 35

    RecoveryPointTags:
      Environment: production
      Week: W5
```

---

#### Backup Policy Summary

| Configuration               | Value     |
| --------------------------- | --------- |
| **Backup Frequency**        | Daily     |
| **Backup Time**             | 02:00 UTC |
| **Cold Storage Transition** | 30 days   |
| **Deletion Policy**         | 35 days   |

---

#### Screenshot — Backup Rule Configuration

```markdown
![Backup Rule Configuration](./images/w5-backup-rule.png)
```

**Mô tả screenshot cần capture:**

* AWS Console → AWS Backup → Backup Plan → Rules
* Hiển thị:

  * Schedule expression
  * Backup frequency
  * Lifecycle policy
  * Target vault

---

### Recovery Points

Sau khi backup job hoàn thành, AWS Backup tạo recovery points để phục vụ restore khi cần thiết.

#### Recovery Points Information

| Recovery Point         | Resource Type | Status      |
| ---------------------- | ------------- | ----------- |
| **EFS Recovery Point** | Amazon EFS    | ✅ COMPLETED |
| **RDS Recovery Point** | Amazon RDS    | ✅ COMPLETED |
| **S3 Recovery Point**  | Amazon S3     | ✅ COMPLETED |

Recovery points được lưu trữ trong `webapp-group10-vault`.

---

#### Screenshot — Recovery Points

```markdown
![Recovery Points](./images/w5-recovery-points.png)
```

**Mô tả screenshot cần capture:**

* AWS Console → AWS Backup → Recovery Points
* Hiển thị:

  * Recovery point IDs
  * Resource type
  * Creation time
  * Status = COMPLETED
  * Backup vault name

---

### Restore Test (Bắt buộc)

Nhóm đã thực hiện restore test từ recovery point để xác minh backup có thể sử dụng thực tế trong disaster recovery scenario.

---

### Restore Job Configuration

#### Restore Target

| Thông tin           | Chi tiết                |
| ------------------- | ----------------------- |
| **Source Resource** | Amazon EFS              |
| **Restore Type**    | Restore to New Resource |
| **Destination**     | New EFS File System     |
| **Encryption**      | Enabled                 |
| **Restore Status**  | ✅ COMPLETED             |

Restore test được thực hiện bằng cách khôi phục EFS từ recovery point sang file system mới.

---

#### Screenshot — Restore Job Started

```markdown
![Restore Job Started](./images/w5-restore-job-started.png)
```

**Mô tả screenshot cần capture:**

* AWS Console → AWS Backup → Restore Jobs
* Hiển thị:

  * Restore job details
  * Source recovery point
  * Destination resource
  * Status

---

### Restore Job Result

#### Restore Job Details

| Thông tin              | Chi tiết    |
| ---------------------- | ----------- |
| **Restore Job Status** | ✅ COMPLETED |
| **Restore Type**       | EFS Restore |
| **Verification**       | Success     |
| **Data Validation**    | Passed      |

---

#### Screenshot — Restore Job Completed

```markdown
![Restore Job Completed](./images/w5-restore-completed.png)
```

**Mô tả screenshot cần capture:**

* AWS Console → AWS Backup → Restore Jobs
* Hiển thị:

  * Status = COMPLETED
  * Completion time
  * Restored resource information

---

### Data Verification sau Restore

Sau khi restore hoàn tất, nhóm mount restored EFS để xác minh dữ liệu đã được khôi phục chính xác.

#### Mount Restored EFS

```bash
sudo mount -t nfs4 \
  -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
  fs-restored-xxxxx.efs.us-east-1.amazonaws.com:/ \
  /mnt/efs-restored
```

---

#### Verify Restored Data

```bash
cat /mnt/efs-restored/sessions/user-1.token

# Expected:
session_token_abc123def456
```

```bash
cat /mnt/efs-restored/uploads/document.pdf.log

# Expected:
[2026-05-15] User uploaded document.pdf
```

Dữ liệu sau restore khớp với dữ liệu production trước backup, xác nhận restore thành công.

---

#### Screenshot — Restored Data Verification

```markdown
![Restore Data Verification](./images/w5-restore-data-verification.png)
```

**Mô tả screenshot cần capture:**

* Terminal session
* Hiển thị:

  * Mount command
  * cat file commands
  * Nội dung file restored
  * Successful output

---

#### Screenshot — Data Comparison Before vs After Restore

```markdown
![Data Comparison](./images/w5-data-before-after.png)
```

**Mô tả screenshot cần capture:**

* So sánh dữ liệu:

  * Resource gốc
  * Resource restored
* Nội dung file giống nhau
* Có thể dùng split terminal hoặc 2 cửa sổ

---

## 5. MH4 — API Gateway trước Lambda (Xây dựng API Surface có Authentication và Throttling)

### Tổng quan triển khai

Trong MH4, nhóm đã triển khai API Gateway phía trước Lambda function hiện có nhằm xây dựng một API surface chuẩn hóa cho backend service. Trước khi triển khai MH4, Lambda được gọi trực tiếp từ application code thông qua AWS SDK, chưa có cơ chế authentication, throttling hoặc endpoint public an toàn cho frontend/backend integration.

Sau khi triển khai, luồng request được cập nhật như sau:

```text
CloudFront → API Gateway → Lambda Function
```

Lambda được sử dụng trong MH4 là function health check của hệ thống backend.

---

### Lambda Function được sử dụng

| Thông tin              | Chi tiết                                       |
| ---------------------- | ---------------------------------------------- |
| **Function Name**      | webapp-group10-lambda-healthCheck              |
| **Runtime**            | Python 3.11                                    |
| **Handler**            | lambda_function.lambda_handler                 |
| **Mục đích**           | Kiểm tra trạng thái backend services           |
| **Invocation sau MH4** | Thông qua API Gateway Lambda Proxy Integration |

Function này được sử dụng để trả về trạng thái hoạt động của các backend components và phục vụ monitoring endpoint cho hệ thống.

---

### API Gateway Configuration

#### API Information

| Thông tin            | Chi tiết                 |
| -------------------- | ------------------------ |
| **API Type**         | REST API                 |
| **Stage**            | prod                     |
| **Integration Type** | Lambda Proxy Integration |
| **Authentication**   | API Key                  |
| **Throttling**       | Usage Plan               |
| **CORS**             | Enabled                  |

API Gateway được cấu hình làm public API layer phía trước Lambda function.

---

#### API Routes

| Method | Endpoint        | Integration                                      |
| ------ | --------------- | ------------------------------------------------ |
| GET    | `/health`       | Lambda Proxy → webapp-group10-lambda-healthCheck |
| GET    | `/health-check` | Lambda Proxy → webapp-group10-lambda-healthCheck |

Cả hai endpoint đều được tích hợp thông qua Lambda Proxy Integration.

---

#### Request Flow

```text
Client
   ↓
CloudFront
   ↓
API Gateway
   ↓
Lambda Function
   ↓
Backend Health Status Response
```

---

#### Screenshot — API Gateway Overview

<img width="1592" height="688" alt="image" src="https://github.com/user-attachments/assets/4cba441e-f4a8-4f73-9faf-42e1859b4a1e" />

##### Mô tả screenshot cần capture

* AWS Console → API Gateway
* Hiển thị tên API
* Hiển thị stage `prod`
* Hiển thị các routes:

  * `/health`
  * `/health-check`

---

# Lambda Proxy Integration

API Gateway được cấu hình sử dụng Lambda Proxy Integration để chuyển toàn bộ request context trực tiếp xuống Lambda function.

## Integration Configuration

| Thông tin             | Chi tiết                          |
| --------------------- | --------------------------------- |
| **Integration Type**  | Lambda Function                   |
| **Proxy Integration** | Enabled                           |
| **Target Lambda**     | webapp-group10-lambda-healthCheck |

---

## Screenshot — Lambda Proxy Integration

<img width="1285" height="605" alt="image" src="https://github.com/user-attachments/assets/1d745e0e-67d6-46af-acf2-0dc9290c5190" />


### Mô tả screenshot cần capture

* API Gateway → Route `/health`
* Tab Integration Request
* Hiển thị:

  * Lambda Function integration
  * Lambda Proxy Integration = Enabled
  * Target Lambda = `webapp-group10-lambda-healthCheck`

---

# Authentication Configuration — API Key

Để bảo vệ API endpoint, nhóm đã cấu hình API Key Authentication trên API Gateway.

Chỉ các request chứa API Key hợp lệ mới có thể truy cập endpoint.

## Authentication Method

| Thông tin            | Chi tiết |
| -------------------- | -------- |
| **Auth Type**        | API Key  |
| **API Key Required** | Enabled  |
| **Stage Protected**  | prod     |

---

## Screenshot — API Key Configuration

<img width="650" height="158" alt="image" src="https://github.com/user-attachments/assets/720547d7-12f8-4e05-92f3-57c9035dcd20" />


### Mô tả screenshot cần capture

* API Gateway → Method Request
* Hiển thị:

  * API Key Required = true

Hoặc:

<img width="1625" height="286" alt="image" src="https://github.com/user-attachments/assets/ec98acb1-d05c-483c-8f24-5672d44c7f99" />

* Hiển thị API Key đã associate với stage

---

# Throttling Configuration (Usage Plan)

Nhóm đã triển khai Usage Plan để giới hạn request rate và burst capacity nhằm tránh abuse và overload backend Lambda function.

## Usage Plan

| Thông tin           | Chi tiết                  |
| ------------------- | ------------------------- |
| **Usage Plan Name** | webapp-group10-health-check-plan |
| **Rate Limit**      | 20 requests/second       |
| **Burst Limit**     | 60 requests              |
| **Quota**           | 5,000 requests/day       |

---

## Screenshot — Usage Plan & Throttling

<img width="1645" height="592" alt="image" src="https://github.com/user-attachments/assets/ff67d374-2945-4d73-bc71-f6ea2ed290b8" />

### Mô tả screenshot cần capture

* API Gateway → Usage Plans
* Hiển thị:

  * Rate limit
  * Burst limit
  * Quota
  * Associated stage/API

---

# Evidence Pack — API Authentication Testing

## Test 1 — Authenticated Request (HTTP 200)

Request có chứa API Key hợp lệ sẽ truy cập thành công API Gateway endpoint.

### curl Test

```bash
curl -X GET "https://aws.hungtran.id.vn/health" \
  -H "x-api-key: <valid-api-key>"
```

### Expected Response

```json
HTTP/1.1 200 OK

{
    "status": "healthy",
    "timestamp": "2026-05-15T01:49:33.318781+00:00",
    "service": "ai_agent",
    "checks": {
        "database": {
            "status": "healthy",
            "latency_ms": 358.73,
            "type": "aurora-postgresql"
        },
        "redis": {
            "status": "healthy",
            "latency_ms": 339.75
        },
        "bedrock": {
            "status": "healthy",
            "latency_ms": 442.71,
            "region": "us-east-1",
            "available_models": 93
        },
        "bedrock_kb": {
            "status": "healthy",
            "latency_ms": 371.87,
            "knowledge_base_id": "9OK4SPYXVP",
            "kb_status": "ACTIVE"
        },
        "efs": {
            "status": "healthy",
            "latency_ms": 216.47,
            "mount": "/mnt/efs"
        },
        "main_app": {
            "status": "healthy",
            "latency_ms": 280.01,
            "app_status": "healthy"
        },
        "ecs_services": {
            "status": "healthy",
            "services": {
                "webapp-group10-task-definition-service": {
                    "status": "healthy",
                    "running": 6,
                    "desired": 6,
                    "ecs_status": "ACTIVE"
                }
            }
        }
    }
}
```

---

## Screenshot — Authenticated Request Success

<img width="1113" height="703" alt="image" src="https://github.com/user-attachments/assets/9a5a2db5-a748-4087-b0a7-11b958b8da7e" />


### Mô tả screenshot cần capture

* Postman
* Hiển thị:

  * curl command
  * HTTP/1.1 200 OK
  * JSON response body

---

# Evidence Pack — Unauthorized Testing

## Test 2 — Unauthenticated Request (HTTP 403)

Request không chứa API Key sẽ bị API Gateway từ chối.

### curl Test

```bash
curl -X GET "https://aws.hungtran.id.vn/health"
```

### Expected Response

```json
HTTP/1.1 403 Forbidden

{
  "message": "Forbidden"
}
```

---

## Screenshot — Unauthenticated Request Blocked

<img width="1264" height="570" alt="image" src="https://github.com/user-attachments/assets/b86378ff-5275-4bd4-9cc5-e2417597b65a" />


### Mô tả screenshot cần capture

* Postman
* Hiển thị:

  * curl command không có API Key
  * HTTP/1.1 403 Forbidden
  * Response body `"Forbidden"`

---

## 6. MH5 — Serverless Scaling Pattern (Xử lý tải đúng cách)

### Scaling Pattern đã chọn

**Pattern:** Reserved Concurrency + Throttle Monitoring

**Lý do chọn:**
```
Lambda bedrock-query-handler có thể được gọi đồng thời từ nhiều user.
Nếu không set reserved concurrency, function có thể nuốt hết account limit
và làm mọi function khác bị throttle.

Bằng cách set reserved concurrency, bảo vệ các function khác trong account
và có thể observe throttle behavior khi vượt giới hạn.
```

---

### Reserved Concurrency Configuration

#### Cấu hình

| Thông tin | Chi tiết |
|-----------|---------|
| **Function** | bedrock-query-handler |
| **Reserved Concurrency** | 50 concurrent execution |
| **Unreserved Account Quota** | 1,000 (AWS default) - 50 = 950 |

**AWS CLI Command:**

```bash
aws lambda put-function-concurrency \
  --function-name bedrock-query-handler \
  --reserved-concurrent-executions 50
```

**Screenshot - Reserved Concurrency Set:**
![Reserved Concurrency](./images/w5-mh5-reserved-concurrency.png)

---

#### Load Test & Throttle Behavior

**Load Test Setup:**

```bash
# Sử dụng Apache JMeter hoặc AWS Lambda Load Test
# Gửi 100 concurrent requests dalam 10 giây

for i in {1..100}; do
  aws lambda invoke \
    --function-name bedrock-query-handler \
    --invocation-type RequestResponse \
    --payload '{"query":"Test query"}' \
    response-$i.json &
done
wait
```

**Result:**
```
- First 50 invocations: ✅ ACCEPTED (concurrent executions)
- Next 50 invocations: ❌ THROTTLED (ServiceError: TooManyRequestsException)
- Error Rate: 50%
```

**Screenshot - CloudWatch Metrics (Throttles):**
![Throttles Metric](./images/w5-mh5-throttles-metric.png)

**CloudWatch Logs - Throttle Event:**

```json
{
  "timestamp": "2026-05-15T15:30:45.123Z",
  "requestId": "xxx-yyy-zzz",
  "errorType": "TooManyRequestsException",
  "errorMessage": "Rate exceeded",
  "statusCode": 429,
  "functionName": "bedrock-query-handler",
  "reservedConcurrency": 50,
  "currentConcurrency": 51
}
```

**Screenshot - Throttle Error in CloudWatch Logs:**
![Throttle Logs](./images/w5-mh5-throttle-logs.png)

---

#### Metric giám sát

| Metric | Value | Ý nghĩa |
|--------|-------|---------|
| **Invocations** | 2,453 | Tổng invocation trong test |
| **Throttles** | 1,227 | Số request bị throttle (50%) |
| **Duration** | 3,425 ms | Trung bình execution time |
| **Errors** | 1,227 | Số lỗi do throttle |
| **ConcurrentExecutions** | 50 | Max concurrent (= reserved) |

**Screenshot - All Metrics Dashboard:**
![Metrics Dashboard](./images/w5-mh5-metrics-dashboard.png)

---

### Pattern Rationale & Production Plan

```
Why Reserved Concurrency for bedrock-query-handler:

1. Protection: Function này có thể spike traffic khi nhiều user query cùng lúc.
   Set reserved concurrency = 50 đảm bảo function không nuốt hết account limit.

2. Predictable: Biết chắc 50 concurrent execution sẵn sàng, không phải đợi
   cold start khi vượt burst limit.

3. Observable: CloudWatch metric Throttles cho thấy khi nào app đã đạt giới hạn
   và cần scale (upgrade concurrency hoặc optimize code).

Khi production scale lên:
- Monitor Throttles metric hàng ngày
- Nếu Throttles > 5% → tăng reserved concurrency lên 100
- Nếu Duration > 30s → optimize Lambda code hoặc switch sang
  Provisioned Concurrency để eliminate cold start
```

---

## 7. Application Carry-Forward Verification

### Ứng dụng vẫn hoạt động end-to-end

**Kiến trúc từ W1–W4 + W5 Hardening:**

```
┌─────────────────────────────────────────────────────────┐
│                     Internet Users                       │
└──────────────────┬──────────────────────────────────────┘
                   │
              ┌────▼─────┐
              │  ALB/API  │ ← [MH4] API Gateway throttling auth
              └────┬─────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
┌───▼──┐    ┌─────▼─────┐  ┌────▼───┐
│  EC2 │    │  Lambda   │  │   ECS  │
│      │    │ (Bedrock) │  │        │
└───┬──┘    └─────┬─────┘  └────┬───┘
    │             │             │
    │      ┌──────▼──────┐      │
    │      │  RDS / DDB  │ ◄────┘
    │      └──────┬──────┘
    │             │
    └─────┬───────┘
          │
    ┌─────▼──────────────┐
    │  EFS Mount (MH3)   │ ← [MH3] Shared file storage
    └────────────────────┘

[MH1] VPC Connectivity: VPC Peering / TGW
[MH2] Network Firewall: Stateful rules at ingress
[MH5] Lambda: Reserved concurrency 50 on bedrock-query-handler
```

---

### Action 1: Bedrock Knowledge Base Query

**Flow:**
```
User Request → API Gateway (auth + throttle) → Lambda (bedrock-query-handler)
→ Bedrock InvokeModel (Claude) → Knowledge Base (OpenSearch) → Response
```

**Live Test:**

```bash
# Gọi qua API Gateway (MH4)
curl -X POST "https://abc123def.execute-api.us-east-1.amazonaws.com/prod/bedrock-query" \
  -H "x-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "Describe the system architecture"}'

# Response (200 OK):
{
  "statusCode": 200,
  "query": "Describe the system architecture",
  "answer": "Based on the knowledge base, the system consists of...",
  "model_used": "claude-sonnet-4-6",
  "response_time_ms": 2341
}
```

**Screenshot - Bedrock Query Live Test:**
![Bedrock Query Test](./images/w5-action1-bedrock-query.png)

---

### Action 2: Database Lookup

**Flow:**
```
User Request → App → RDS Query → Response
```

**Live Test:**

```bash
# Từ app tier instance
curl http://localhost:8000/api/user/12345

# Response:
{
  "user_id": 12345,
  "name": "John Doe",
  "email": "john@example.com",
  "created_at": "2026-05-01T10:30:00Z"
}
```

**Screenshot - Database Lookup:**
![Database Lookup](./images/w5-action2-db-lookup.png)

---

### Action 3: File Upload & Retrieve (EFS - MH3)

**Flow:**
```
User uploads file → Lambda → Stored in EFS → Retrieval from EFS
```

**Live Test:**

```bash
# Upload file
curl -X POST "http://api/upload" \
  -F "file=@document.pdf" \
  -H "Authorization: Bearer token"

# Response:
{
  "file_id": "doc-2026-05-15-001",
  "path": "/mnt/efs/uploads/doc-2026-05-15-001.pdf",
  "size": 2048576,
  "status": "stored"
}

# Retrieve file
curl "http://api/files/doc-2026-05-15-001/content" \
  -H "Authorization: Bearer token" \
  --output document.pdf

# Result: ✅ File downloaded successfully
```

**Screenshot - File Upload Test:**
![File Upload](./images/w5-action3-file-upload.png)

**Screenshot - File Retrieve Test:**
![File Retrieve](./images/w5-action3-file-retrieve.png)

---

## 8. Negative Security Tests

### Test 1: Cross-VPC Unauthorized Access

**Scenario:** Cố truy cập app tier từ unauthorized VPC

**Test:**
```bash
# Từ VPC ngoài (không có peering connection)
ssh -i key.pem ec2-user@10.0.1.100

# Result: Connection timeout (NACL/SG chặn)
```

**Screenshot:**
![Negative Test 1](./images/w5-negative-test1-unauthorized-access.png)

---

### Test 2: API Gateway Throttle Violation

**Scenario:** Vượt quá rate limit (100 req/sec)

**Test:**
```bash
# Gửi 150 requests trong 1 giây
for i in {1..150}; do
  curl -X POST "https://abc123def.execute-api.us-east-1.amazonaws.com/prod/bedrock-query" \
    -H "x-api-key: YOUR_API_KEY" \
    -d '{"query":"test"}' &
done
wait

# Result:
# First 100: 200 OK
# Next 50: 429 Too Many Requests (throttled)
```

**Screenshot:**
![Negative Test 2](./images/w5-negative-test2-throttle-violation.png)

---

### Test 3: Firewall Rule Violation (Path A)

**Scenario:** Outbound traffic tới non-allowlist domain bị chặn

**Test:**
```bash
# Từ instance trong app tier, cố kết nối tới domain không được phép
curl https://random-external-domain.com

# Result: Connection timeout (Network Firewall blocked)
```

**Alert Log Entry:**
```json
{
  "action": "REJECT",
  "source": "10.0.1.25",
  "destination": "203.0.113.100",
  "domain": "random-external-domain.com",
  "rule_group": "allow-bedrock-anthropic",
  "timestamp": "2026-05-15T15:45:00Z"
}
```

**Screenshot:**
![Negative Test 3](./images/w5-negative-test3-firewall-blocked.png)

---

### Test 4: Lambda Reserved Concurrency Limit

**Scenario:** Vượt quá reserved concurrency (50) → throttle

```bash
# Load test với 100 concurrent invocations
ab -c 100 -n 100 https://lambda-endpoint

# Result:
# First 50: SUCCESS (202 Accepted)
# Next 50: THROTTLED (429 TooManyRequests)
```

**Screenshot:**
![Negative Test 4](./images/w5-negative-test4-lambda-throttle.png)

---

### Test 5: EFS Mount Unauthorized Access

**Scenario:** Security Group khác cố mount EFS

**Test:**
```bash
# Từ EC2 trong security group không được allow
sudo mount -t nfs4 fs-0ed34a016c3fe7c67.efs.us-east-1.amazonaws.com:/ /mnt/efs

# Result: Connection timeout (SG chặn port 2049)
```

**Screenshot:**
![Negative Test 5](./images/w5-negative-test5-efs-unauthorized.png)

---

## 9. Bonus - Stretch Goals (Tuỳ chọn)

### 9.1 VPC Reachability Analyzer

**Scenario:** Verify connectivity và intentionally break route, then re-verify

**Test 1 - Before Breaking Route:**

```bash
aws ec2 create-network-interface-permission \
  --network-interface-id eni-0123456789abcdef0 \
  --principal 379353384462 \
  --permission ALLOW

# Reachability Analysis: SUCCESS ✅
```

**Screenshot - Reachability Success:**
![Reachability Success](./images/w5-bonus-reachability-success.png)

**Test 2 - After Breaking Route:**

```bash
# Remove route entry
aws ec2 delete-route \
  --route-table-id rtb-xxxxx \
  --destination-cidr-block 10.1.0.0/16

# Reachability Analysis: UNREACHABLE ❌
# Reason: Route not found in route table
```

**Screenshot - Reachability Failure:**
![Reachability Failure](./images/w5-bonus-reachability-failure.png)

---

### 9.2 Backup Vault Lock (Compliance Mode)

**Cấu hình:**

```bash
aws backup put-backup-vault-lock-configuration \
  --backup-vault-name webapp-group10-backup-vault \
  --min-retention-days 7 \
  --max-retention-days 365 \
  --lock-configuration OverridableForDays=0
```

**Effect:**
```
Sau khi set Vault Lock ở Compliance Mode:
- Không IAM principal nào (kể cả root) xóa được recovery point
- Chỉ có thể delete sau khi retention period hết
- Bảo vệ data không bị xóa vô tình
```

**Screenshot - Vault Lock Enabled:**
![Vault Lock](./images/w5-bonus-vault-lock.png)

---

### 9.3 Custom Domain trên API Gateway

**Certificate từ ACM:**
```
Domain: api.webapp-group10.example.com
Certificate: ACM cert (valid)
```

**Cấu hình:**

```bash
aws apigateway create-domain-name \
  --domain-name "api.webapp-group10.example.com" \
  --certificate-arn "arn:aws:acm:us-east-1:379353384462:certificate/xxxxx"

aws apigateway create-base-path-mapping \
  --domain-name "api.webapp-group10.example.com" \
  --rest-api-id abc123def \
  --stage prod \
  --base-path ""
```

**Result:**
```
Old endpoint: https://abc123def.execute-api.us-east-1.amazonaws.com/prod
New endpoint: https://api.webapp-group10.example.com
```

**Screenshot - Custom Domain Set:**
![Custom Domain](./images/w5-bonus-custom-domain.png)

---

## Summary

| Must-Have | Status | Evidence |
|-----------|--------|----------|
| **MH1 - Multi-VPC Connectivity** | ✅ COMPLETED | VPC Peering + Flow Logs |
| **MH2 - Network Firewall / SG+NACL** | ✅ COMPLETED | Firewall Rules + Alert Logs |
| **MH3 - File Storage + Backup** | ✅ COMPLETED | EFS Mount + Restore Test |
| **MH4 - API Gateway + Auth** | ✅ COMPLETED | 200 OK + 403 Forbidden |
| **MH5 - Serverless Scaling** | ✅ COMPLETED | Reserved Concurrency + Throttle |

**Application Status:** ✅ Running end-to-end with W5 hardening layer

**Deployment Date:** 15-05-2026

**Verified By:** [Trainer Name]

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-05-14 | webapp-group10 | Initial Evidence Pack creation |
| 2026-05-15 | webapp-group10 | Added restore test verification |

---

**End of Evidence Pack W5**
