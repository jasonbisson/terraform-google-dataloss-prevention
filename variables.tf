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

variable "region" {
  description = "Google Cloud region to deploy resources"
  type        = string
  default     = "us-central"
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

variable "dlp_rolesList" {
  type    = list(string)
  default = ["roles/dlp.admin", "roles/dlp.serviceAgent"]
}