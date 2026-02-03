# AWS Cost Analysis Report

**Date:** 2026-02-01
**Project:** Ecommerce Realtime Analytics Pipeline

## 💰 Executive Summary
**Current Estimated Ongoing Cost:** **~$0.01 / month** 
**Status:** ✅ **Safe** (No expensive hourly resources found)

All deployed resources are **serverless** and **usage-based**, meaning you only pay when you run queries, crawl data, or ingest events. Since the system is currently idle, costs are negligible.

---

## 🔍 Resource Breakdown

### 1. Storage (S3)
*   **Resources:** 3 Buckets (Bronze, Silver, Gold)
*   **Current Usage:** < 50 MB total
*   **Cost Model:** $0.023 per GB / month
*   **Estimated Cost:** **$0.00** (Fraction of a penny)

### 2. Compute (Lambda)
*   **Resources:** `ecommerce-analytics-dev-ingestion`
*   **Status:** Idle (0 invocations in last 24h)
*   **Cost Model:** $0.20 per 1M requests + duration
*   **Estimated Cost:** **$0.00**

### 3. Data Catalog (Glue)
*   **Resources:** 1 Database, 1 Crawler
*   **Status:** Ready / Not Running
*   **Cost Model:** $0.44 per DPU-Hour (billed per run)
*   **Estimated Cost:** **$0.00** (unless crawler is manually run)
    *   *Note:* Each crawler run costs a minimum of ~$0.08 (assuming ~10 mins minimum duration billing at 2 DPUs).

### 4. Query Engine (Athena)
*   **Resources:** 1 Workgroup `ecommerce-analytics-dev-analytics`
*   **Status:** Idle
*   **Cost Model:** $5.00 per TB scanned
*   **Estimated Cost:** **$0.00**
    *   *Note:* Your dataset is very small (< 50MB). You could run thousands of queries for < $0.01.

### 5. High-Cost Risks (Verified Absent)
*   ❌ **Kinesis Data Streams:** None found (No hourly shard costs).
*   ❌ **EC2 Instances:** None found.
*   ❌ **NAT Gateways:** None found.
*   ❌ **Redshift:** Commented out in Terraform (Not deployed).

---

## 📉 Recommendations

1.  **Keep it Idle:** You can leave this infrastructure deployed without incurring costs.
2.  **Monitor Glue:** Avoid scheduling the Glue Crawler to run frequently (e.g., every hour) unnecessarily. Run it on-demand or daily.
3.  **Budget Alert:** Your Terraform setup includes a budget tag (`Budget = "Under5Dollars"`), which is a good practice.
4.  **Clean Up:** If you want to delete everything to be 100% sure:
    ```bash
    cd terraform
    terraform destroy
    ```
