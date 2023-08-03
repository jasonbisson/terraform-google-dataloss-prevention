/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
variable "environment" {
  description = "Environment tag to help identify the entire deployment"
  type        = string
  default     = "dlp"
}

variable "project_name" {
  description = "Prefix of Google Project name"
  type        = string
  default     = "prj"
}

variable "org_id" {
  description = "The numeric organization id"
  type        = string
}

variable "folder_id" {
  description = "The folder to deploy project in"
  type        = string
}

variable "billing_account" {
  description = "The billing account id associated with the project, e.g. XXXXXX-YYYYYY-ZZZZZZ"
  type        = string
}

variable "region" {
  description = "Google Cloud region to deploy resources"
  type        = string
  default     = "us-central1"
}

variable "storage_entry_point" {
  description = "Cloud Function to process storage events"
  type        = string
  default     = "create_DLP_job"
}

variable "pubsub_entry_point" {
  description = "Cloud Function to process pub sub events"
  type        = string
  default     = "resolve_DLP"
}

variable "runtime" {
  description = "Cloud Function runtime"
  type        = string
  default     = "python310"
}
