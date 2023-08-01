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

module "dlp_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 11.0"

  name              = "${var.project_name}-${var.environment}-${random_id.random_suffix.hex}"
  random_project_id = "false"
  org_id            = var.org_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account

  activate_apis = ["storage-component.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "dlp.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "artifactregistry.googleapis.com",
    "pubsub.googleapis.com",
    "cloudasset.googleapis.com",
    "eventarc.googleapis.com"
  ]
}

resource "random_id" "random_suffix" {
  byte_length = 4
}

resource "google_service_account" "cloudfunction" {
  project      = module.project.project_id
  account_id   = "${var.environment}-${random_id.random_suffix.hex}"
  display_name = "${var.environment}-${random_id.random_suffix.hex}"
}

resource "google_project_iam_member" "binding" {
  project    = module.project.project_id
  role       = "roles/dlp.serviceAgent"
  member     = "serviceAccount:${google_service_account.cloudfunction.email}"
}

resource "google_storage_bucket" "quarantine_bucket" {
  project                     = module.project.project_id
  name                        = "${var.environment}-quarantine-${random_id.random_suffix.hex}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "sensitive_bucket" {
  project                     = module.project.project_id
  name                        = "${var.environment}-sensitive-${random_id.random_suffix.hex}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}


resource "google_storage_bucket" "non_sensitive_bucket" {
  project                     = module.project.project_id
  name                        = "${var.environment}-non-sensitive-${random_id.random_suffix.hex}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "gcf_source_bucket" {
  project                     = module.project.project_id
  name                        = "${var.environment}-dlpfunction-${random_id.random_suffix.hex}"
  uniform_bucket_level_access = true
  location                    = var.region
  depends_on                  = [google_project_service.project_services]
}

data "archive_file" "gcf_zip_file" {
  type        = "zip"
  output_path = "${path.module}/files/${var.environment}.zip"

  source {
    content  = file("${path.module}/files/main.py")
    filename = "main.py"
  }

  source {
    content  = file("${path.module}/files/requirements.txt")
    filename = "requirements.txt"
  }

}

resource "google_storage_bucket_object" "gcf_zip_gcs_object" {
  name   = "${var.environment}-dlpcode-${random_id.random_suffix.hex}"
  bucket = google_storage_bucket.gcf_source_bucket.name
  source = data.archive_file.gcf_zip_file.output_path
}

resource "google_pubsub_topic" "pubsub_topic" {
  project = module.project.project_id
  name    = "${var.environment}-${random_id.random_suffix.hex}"
}

resource "google_pubsub_subscription" "pubsub_subscription" {
  name  = "${var.environment}-${random_id.random_suffix.hex}"
  topic = google_pubsub_topic.pubsub_topic.name
}

resource "google_cloudfunctions_function" "storage_function" {
  project               = module.project.project_id
  name                  = "${var.environment}-storage-${random_id.random_suffix.hex}"
  runtime               = var.runtime
  source_archive_bucket = google_storage_bucket.gcf_source_bucket.name
  source_archive_object = google_storage_bucket_object.gcf_zip_gcs_object.name
  region                = var.region
  ingress_settings      = "ALLOW_INTERNAL_ONLY"
  service_account_email = google_service_account.cloudfunction.email
  entry_point           = var.storage_entry_point
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.quarantine_bucket.name
  }
  depends_on = [google_project_service.project_services]
}

resource "google_cloudfunctions_function" "pubsub_function" {
  project               = module.project.project_id
  name                  = "${var.environment}-pubsub-${random_id.random_suffix.hex}"
  runtime               = var.runtime
  source_archive_bucket = google_storage_bucket.gcf_source_bucket.name
  source_archive_object = google_storage_bucket_object.gcf_zip_gcs_object.name
  region                = var.region
  ingress_settings      = "ALLOW_INTERNAL_ONLY"
  service_account_email = google_service_account.cloudfunction.email
  entry_point           = var.pubsub_entry_point
  eevent_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${module.project.project_id}/topics/${google_pubsub_topic.pubsub_topic.name}"
  }
  depends_on = [google_project_service.project_services]
}
