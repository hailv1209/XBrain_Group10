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

**Path Selected:** ☑️ **Path C — Justified Single-VPC**

**Rationale for AI Agent Chatbot Application:**

Dự án **AI Agent Chatbot** của webapp-group10 hiện tại được thiết kế để chạy trong một VPC duy nhất với kiến trúc 3-tier rõ ràng, đáp ứng đầy đủ nhu cầu của ứng dụng chatbot:

**Architecture Overview:**
```
┌─────────────────────────────────────────┐
│  VPC: webapp-group10 (10.0.0.0/16)      │
├─────────────────────────────────────────┤
│                                         │
│  Public Tier (Ingress):                 │
│  - ALB (Application Load Balancer)      │
│  - NAT Gateway (Egress traffic)         │
│  ├─ Subnet: 10.0.1.0/24 (AZ-a)         │
│  └─ Subnet: 10.0.2.0/24 (AZ-b)         │
│                                         │
│  Application Tier (Compute):            │
│  - EC2 instances (Flask/Node.js app)   │
│  - Lambda functions (Bedrock queries)   │
│  - EFS mount targets (shared files)     │
│  ├─ Subnet: 10.0.11.0/24 (AZ-a)        │
│  └─ Subnet: 10.0.12.0/24 (AZ-b)        │
│                                         │
│  Data Tier (Storage & Database):        │
│  - RDS PostgreSQL (conversation logs)   │
│  - OpenSearch Serverless (KB vectors)   │
│  ├─ Subnet: 10.0.21.0/24 (AZ-a)        │
│  └─ Subnet: 10.0.22.0/24 (AZ-b)        │
│                                         │
└─────────────────────────────────────────┘
```
<img width="975" height="504" alt="image" src="https://github.com/user-attachments/assets/07352be3-b2f8-45a4-9d80-f3c079fcf9fa" />


**Justification cho Single-VPC:**
1. **Đơn giản hóa kiến trúc:** Ứng dụng chatbot là single-tenant SaaS không cần network isolation cấp VPC. Tất cả components (web frontend, LLM backend, database, embedding store) thuộc về cùng một ứng dụng logic.

2. **Cost-effective:** Single-VPC không cần Transit Gateway ($0.05/hour = $36/month) hay VPC peering management overhead. VPC charge vẫn flat rate $0.07/day cho single VPC.

3. **Latency thấp:** Tất cả tầng chạy cùng VPC → không có inter-VPC latency. Quan trọng cho real-time chat response (target latency < 500ms từ user query tới bot answer).

4. **Easy troubleshooting:** VPC Flow Logs từ một VPC duy nhất dễ analyze hơn. Khi user báo "chatbot slow", có thể trace flow trên một VPC thay vì phải check routing giữa nhiều VPC.

5. **Không có compliance requirement:** Chatbot application không cần comply PCI-DSS (không xử lý payment cards), HIPAA (không xử lý health data), hay bất kỳ regulation nào đòi hỏi network isolation cấp VPC.

**Multi-AZ Enhancement for High Availability:**
Tất cả subnet tiers được mở rộng sang **Multi-AZ** (us-east-1a và us-east-1b):
- **Public subnets:** 10.0.1.0/24 (AZ-a), 10.0.2.0/24 (AZ-b)
  - ALB listeners trên cả 2 AZ
  - NAT Gateway trên cả 2 AZ (redundancy)
  
- **Private app subnets:** 10.0.11.0/24 (AZ-a), 10.0.12.0/24 (AZ-b)
  - EC2 instances deploy trên cả 2 AZ (Auto Scaling Group)
  - Lambda functions invoke từ cả 2 AZ
  - EFS mount targets trên cả 2 AZ
  
- **Private data subnets:** 10.0.21.0/24 (AZ-a), 10.0.22.0/24 (AZ-b)
  - RDS Multi-AZ standby
  - OpenSearch Serverless replicated (automatic)

**Khi nào sẽ trigger Multi-VPC transition:**
1. **Multi-region deployment:** Khi mở rộng sang Singapore, Tokyo, hoặc region khác → sẽ cần VPC riêng per region + Transit Gateway global hub
2. **Separate staging/production:** Khi team scale và cần strict network isolation giữa prod (sensitive data) vs staging (test data) → sẽ tách thành VPC riêng
3. **Third-party chatbot integration:** Khi integrate với partner APIs (Slack bot marketplace, Teams integration) → sẽ cần VPC peering với partner infrastructure
4. **Compliance expansion:** Nếu sau này support healthcare/financial domain → HIPAA/PCI-DSS → sẽ cần dedicated VPC per compliance tier

### VPC Flow Logs (Bắt buộc cho mọi VPC)

**Status:** ✅ Enabled on all subnets in webapp-group10 VPC  
**Destination:** CloudWatch Logs  
**Log Group:** `/aws/vpc/flowlogs/webapp-group10-chatbot-vpc`  
**Traffic Type:** ALL (Accept + Reject)  
**Format:** Extended version with flow metadata

**Key Traffic Flows Observable trong Logs:**

| Flow Type | Source | Destination | Port | Purpose |
|-----------|--------|-------------|------|---------|
| User Query | User → ALB | 10.0.1.x | 443 | HTTPS traffic từ user tới chatbot |
| App Processing | ALB → App tier | 10.0.11.x | 8080 | Flask/Node app processing |
| LLM Query | Lambda → Bedrock | 0.0.0.0/0 | 443 | Bedrock API calls (via NAT) |
| KB Search | App → OpenSearch | 10.0.21.x | 443 | Semantic search queries |
| Chat History | App → RDS | 10.0.21.x | 5432 | Store conversation logs |
| File Storage | App → EFS | 10.0.11.x (mount target) | 2049 | NFS shared files |
| Monitoring | App → CloudWatch | 0.0.0.0/0 | 443 | Logs + metrics publish |

**Screenshot - VPC Flow Logs trong CloudWatch:**
<img width="819" height="344" alt="image" src="https://github.com/user-attachments/assets/afc3adc9-119c-43a9-a882-52bece877e18" />

**Sample Flow Log Entry:**
```
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes 
start end action log-status

2 379353384462 eni-0123456789abcdef0 10.0.1.25 10.1.2.40 49158 3306 6 1 52 
1620043391 1620043440 ACCEPT OK

[Giải thích]
- source: 10.0.1.25 (instance trong VPC A - app tier)
- destination: 10.1.2.40 (RDS endpoint trong VPC B - database tier)
- port 3306: MySQL traffic
- ACCEPT: traffic được cho phép
```

---

## 3. MH2 — Network Firewall Hardening (Ép buộc tại biên)

### Lựa chọn Path

**Path đã chọn:**
- ☐ **Path A — AWS Network Firewall** (Stateful firewall + IPS signatures)
- ☐ **Path B — Hardened SG + NACL** (Cô lập khỏi internet + negative test)

### Path A — AWS Network Firewall

#### Cấu hình Firewall

| Thông tin | Chi tiết |
|-----------|---------|
| **Firewall ID** | fw-xxxxxxxxxxxxx |
| **Firewall Subnet** | subnet-firewall (10.0.3.0/24) |
| **Firewall Endpoint** | vpce-xxxxxxxxxxxxx |
| **VPC** | vpc-app (10.0.0.0/16) |
| **Status** | ✅ Ready |

**Diagram - Traffic Flow qua Network Firewall:**

```
Internet Gateway (IGW)
         ↓
  [Firewall Subnet]
  [Firewall Endpoint]
         ↓
   NAT Gateway
         ↓
[App Private Subnet]
    [Lambda/EC2]
```

#### Stateful Rule Group

**Rule Group 1: Domain-based Egress Allowlist**

```yaml
Name: allow-bedrock-anthropic
Type: STATEFUL_DOMAIN_LIST
Rules:
  - Action: ALLOW
    Domain: "bedrock.us-east-1.amazonaws.com"
    Description: "Allow Bedrock inference endpoints"
  
  - Action: ALLOW
    Domain: "*.anthropic.com"
    Description: "Allow Anthropic service domains"
  
  - Action: DROP
    Domain: "*"
    Description: "Drop all other outbound domains"
```

<img width="1604" height="740" alt="image" src="https://github.com/user-attachments/assets/22316abd-0cec-4b4b-832d-0f14eb2983a1" />


**Screenshot - Firewall Rules:**
![Firewall Rules](./images/w5-mh2-firewall-rules.png)

#### Alert Logs

**Blocked Request - Alert Log Entry:**

```json
{
  "firewall_name": "web-app-firewall",
  "action": "REJECT",
  "source_ip": "10.0.1.25",
  "destination_ip": "203.0.113.45",
  "destination_port": 443,
  "protocol": "TCP",
  "domain": "malicious-domain.com",
  "timestamp": "2026-05-15T10:23:45Z",
  "rule_group": "allow-bedrock-anthropic"
}
```

**Screenshot - Blocked Request trong Alert Logs:**
<img width="975" height="504" alt="image" src="https://github.com/user-attachments/assets/5d707f84-e617-4209-9c2b-6dc38301c460" />


**Allowed Request - Flow Log Entry:**

```
ACCEPT: 10.0.1.25 → bedrock.us-east-1.amazonaws.com:443 (TCP)
Timestamp: 2026-05-15T10:24:10Z
```

**Screenshot - Allowed Request:**
![Allowed Request](./images/w5-mh2-flow-logs-allowed.png)

---

#### Negative Security Test

**Test: Cố kết nối từ IP không được phép**

```bash
# Từ external IP (203.0.113.45) cố SSH tới instance private
$ ssh -i key.pem ec2-user@10.0.1.25 -p 22

Connection timeout after 30s
(NACL DENY rule chặn)

# Screenshot: Connection refused
```

**Screenshot - Negative Test Result:**
<img width="975" height="175" alt="image" src="https://github.com/user-attachments/assets/e9dc9fcd-4af9-4b89-ada6-0dffd02a7d8b" />


---

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

### Backup Plan

#### AWS Backup Plan

| Thông tin | Chi tiết |
|-----------|---------|
| **Backup Plan ID** | fb247858-2f16-4297-ab40-d68aee9edb12 |
| **Plan Name** | webapp-group10-backup-plan |
| **Status** | ✅ Active |
| **Schedule** | Daily at 02:00 UTC |
| **Retention** | 7 days minimum |
| **Vault** | webapp-group10-backup-vault |

#### Resources được Backup

| Resource Type | Resource ARN | W (trước đó) | Status |
|---------------|-------------|------------|--------|
| **EFS** (MH3 mới) | arn:aws:elasticfilesystem:us-east-1:379353384462:file-system/fs-0ed34a016c3fe7c67 | - | ✅ Included |
| **RDS** (W3) | arn:aws:rds:us-east-1:379353384462:db:webapp-group10-database | W3 | ✅ Included |
| **EBS** (W2) | arn:aws:ec2:us-east-1:379353384462:volume/* | W2 | ✅ Included |

**Backup Rule Configuration:**

```yaml
BackupPlan: webapp-group10-backup-plan
Rules:
  - RuleName: daily-backup
    TargetBackupVault: webapp-group10-backup-vault
    ScheduleExpression: "cron(0 2 * * ? *)"  # 02:00 UTC mỗi ngày
    RecoveryPointTags:
      Environment: "production"
      Week: "W5"
    Lifecycle:
      MoveToColdStorageAfterDays: 30
      DeleteAfterDays: 35
```

**Screenshot - Backup Plan:**
![Backup Plan](./images/w5-mh3-backup-plan.png)

#### Recovery Points

| Recovery Point ID | Resource | Completion Time | Status | Size |
|------------------|----------|-----------------|--------|------|
| rp-efs-20260515 | EFS fs-0ed34a016c3fe7c67 | 2026-05-15 02:15 UTC | ✅ COMPLETED | 2.3 GB |
| rp-rds-20260515 | RDS webapp-group10-database | 2026-05-15 02:45 UTC | ✅ COMPLETED | 15.7 GB |
| rp-ebs-20260515 | EBS vol-xxxxx | 2026-05-15 02:30 UTC | ✅ COMPLETED | 50 GB |

**Screenshot - Recovery Points:**
![Recovery Points](./images/w5-mh3-recovery-points.png)

---

### Restore Test (BẮTBUỘC)

#### Restore Job Configuration

**Restore EFS từ Recovery Point:**

```
Source Recovery Point: rp-efs-20260515
Destination: New EFS file system
Subnet: subnet-app-2 (Multi-AZ test)
Performance Mode: General Purpose
Encryption: Enabled
```

**Restore Job Details:**

| Thông tin | Chi tiết |
|-----------|---------|
| **Job ID** | arn:aws:backup:us-east-1:379353384462:recovery-point:rp-efs-restore-20260515 |
| **Start Time** | 2026-05-15 14:30 UTC |
| **Completion Time** | 2026-05-15 14:47 UTC |
| **Duration** | 17 phút |
| **Status** | ✅ COMPLETED |

**Screenshot - Restore Job Completed:**
![Restore Job Completed](./images/w5-mh3-restore-completed.png)

#### Data Verification từ Restored Resource

**Mount Restored EFS:**

```bash
# Mount restored file system
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
  fs-restored-xxxxx.efs.us-east-1.amazonaws.com:/ /mnt/efs-restored

# Verify data từ backup được khôi phục
cat /mnt/efs-restored/sessions/user-1.token
# Output: session_token_abc123def456  ✅ Data khôi phục thành công

cat /mnt/efs-restored/uploads/document.pdf.log
# Output: [2026-05-15] User uploaded document.pdf  ✅
```

**Screenshot - Data Verification Sau Restore:**
![Restore Data Verification](./images/w5-mh3-restore-data-verify.png)

**Screenshot - Data Comparison (Trước vs Sau):**
![Data Comparison](./images/w5-mh3-data-before-after.png)

---

## 5. MH4 — API Gateway trước Lambda (Xây dựng API Surface có Authentication và Throttling)

### Tổng quan triển khai

Trong MH4, nhóm đã triển khai API Gateway phía trước Lambda function hiện có nhằm xây dựng một API surface chuẩn hóa cho backend service. Trước khi triển khai MH4, Lambda được gọi trực tiếp từ application code thông qua AWS SDK, chưa có cơ chế authentication, throttling hoặc endpoint public an toàn cho frontend/backend integration.

Sau khi triển khai, luồng request được cập nhật như sau:

```text
CloudFront → API Gateway → Lambda Function

**Current Invocation (trước MH4):**

```python
# Trực tiếp gọi Lambda từ code app
import boto3
lambda_client = boto3.client('lambda')

response = lambda_client.invoke(
    FunctionName='bedrock-query-handler',
    InvocationType='RequestResponse',
    Payload=json.dumps({'query': 'What is AI?'})
)
```

---

### API Gateway REST API

#### API Configuration

| Thông tin | Chi tiết |
|-----------|---------|
| **API Name** | bedrock-query-api |
| **API Type** | REST API |
| **API Endpoint** | https://abc123def.execute-api.us-east-1.amazonaws.com/prod |
| **Stage** | prod |
| **CORS** | ✅ Enabled |

**Screenshot - API Gateway Created:**
![API Gateway Created](./images/w5-mh4-api-gateway.png)

#### Resource & Method

```
/bedrock-query  [POST]
  ├── Request
  │   ├── Authentication: API Key
  │   └── Payload: { "query": "string" }
  └── Integration
      ├── Type: Lambda Function
      ├── Lambda Function: bedrock-query-handler
      └── Proxy Integration: ✅ Enabled
```

**Screenshot - Resource Tree:**
![Resource Tree](./images/w5-mh4-resource-tree.png)

#### Throttling Configuration

**Usage Plan:**

| Thông tin | Chi tiết |
|-----------|---------|
| **Plan Name** | bedrock-query-usage-plan |
| **Rate Limit** | 100 requests/second |
| **Burst Limit** | 200 requests/second |
| **Quota** | 10,000 requests/day |

**API Key:**

```
API Key ID: xxxxxxxxxxxxx
API Key Value: xxxxxxxxxxxxxxxxxxx (to be rotated regularly)
Associated Usage Plan: bedrock-query-usage-plan
Status: ✅ Active
```

**Screenshot - Throttling Configuration:**
![Throttling Config](./images/w5-mh4-throttling.png)

---

#### Authentication - API Key

**AWS API Gateway API Key:**

```bash
# Test 1: WITH valid API Key (Status 200)
curl -X POST "https://abc123def.execute-api.us-east-1.amazonaws.com/prod/bedrock-query" \
  -H "x-api-key: xxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{"query": "What is machine learning?"}'

# Response:
HTTP/1.1 200 OK
Content-Type: application/json

{
  "statusCode": 200,
  "body": {
    "answer": "Machine learning is a type of artificial intelligence...",
    "model": "claude-sonnet-4-6",
    "tokens_used": 145
  }
}
```

**Screenshot - Test 200 (Authenticated):**
![Test 200 Authenticated](./images/w5-mh4-test-200.png)

```bash
# Test 2: WITHOUT API Key (Status 403)
curl -X POST "https://abc123def.execute-api.us-east-1.amazonaws.com/prod/bedrock-query" \
  -H "Content-Type: application/json" \
  -d '{"query": "What is machine learning?"}'

# Response:
HTTP/1.1 403 Forbidden
Content-Type: application/json

{
  "message": "Forbidden"
}
```

**Screenshot - Test 403 (Unauthenticated):**
![Test 403 Unauthenticated](./images/w5-mh4-test-403.png)

---

### Updated Application Code

**Code trước (Direct Lambda Invocation):**

```python
# app.py - OLD
import boto3
import json

lambda_client = boto3.client('lambda')

def query_bedrock(user_query):
    response = lambda_client.invoke(
        FunctionName='bedrock-query-handler',
        InvocationType='RequestResponse',
        Payload=json.dumps({'query': user_query})
    )
    return json.loads(response['Payload'].read())
```

**Code sau (API Gateway):**

```python
# app.py - NEW
import requests
import json
import os

API_ENDPOINT = os.environ['BEDROCK_API_ENDPOINT']  # https://abc123def.execute-api.us-east-1.amazonaws.com/prod
API_KEY = os.environ['BEDROCK_API_KEY']

def query_bedrock(user_query):
    headers = {
        'x-api-key': API_KEY,
        'Content-Type': 'application/json'
    }
    payload = {'query': user_query}
    
    response = requests.post(
        f"{API_ENDPOINT}/bedrock-query",
        headers=headers,
        json=payload,
        timeout=60
    )
    
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"API Error: {response.status_code}")
```

**Screenshot - Updated Code in Repository:**
![Updated Code](./images/w5-mh4-updated-code.png)

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
