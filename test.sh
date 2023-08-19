export PROJECT_ID=$(gcloud config get-value project)
gsutil mb gs://$PROJECT_ID
curl https://cdn.qwiklabs.com/8tnHNHkj30vDqnzokQ%2FcKrxmOLoxgfaswd9nuZkEjd8%3D --output usa_names.csv
gsutil cp usa_names.csv gs://$PROJECT_ID
curl https://cdn.qwiklabs.com/8tnHNHkj30vDqnzokQ%2FcKrxmOLoxgfaswd9nuZkEjd8%3D --output head_usa_names.csv
gsutil cp head_usa_names.csv gs://$PROJECT_ID
bq mk lake
bq load --autodetect --source_format=CSV lake.usa_names gs://qwiklabs-gcp-03-fdfcc139c9e4/csv
bq load --autodetect --source_format=CSV lake.usa_names_transformed gs://qwiklabs-gcp-03-fdfcc139c9e4/csv
bq load --autodetect --source_format=CSV lake.usa_names_enriched gs://qwiklabs-gcp-03-fdfcc139c9e4/csv
bq load --autodetect --source_format=CSV lake.orders_denormalized_sideinput gs://qwiklabs-gcp-03-fdfcc139c9e4/csv
