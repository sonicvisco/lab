gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    sourcerepo.googleapis.com
export PROJECT_ID=$(gcloud config get-value project)
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$(gcloud projects describe $PROJECT_ID \
--format="value(projectNumber)")@cloudbuild.gserviceaccount.com --role="roles/container.developer"


git config --global user.email $student
git config --global user.name ah
export CLUSTER_NAME=hello-cluster
export ZONE=us-central1-a
export REGION=us-central1
export REPO=my-repository

gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="ah"

gcloud beta container --project "$PROJECT_ID" clusters create "$CLUSTER_NAME" --zone "$ZONE" --no-enable-basic-auth --cluster-version "1.27.3-gke.100" --release-channel "regular" --machine-type "e2-medium" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true  --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" --subnetwork "projects/$PROJECT_ID/regions/$REGION/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --enable-autoscaling --min-nodes "2" --max-nodes "6" --location-policy "BALANCED" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes --node-locations "$ZONE"
kubectl create namespace prod	
kubectl create namespace dev



gcloud source repos create sample-app
git clone https://source.developers.google.com/p/$PROJECT_ID/r/sample-app
cd ~
gsutil cp -r gs://spls/gsp330/sample-app/* sample-app

git init
cd sample-app/
git add .
git commit -m "ah" 
git push -u origin master

git branch dev
git checkout dev
git push -u origin dev

gcloud beta builds triggers create cloud-source-repositories \
--name="sample-app-prod-deploy" \
--repo="sample-app" --branch-pattern="^master$" \
--build-config="cloudbuild.yaml"


gcloud beta builds triggers create cloud-source-repositories \
--name="sample-app-dev-deploy" \
--repo="sample-app" --branch-pattern="^dev$" \
--build-config="cloudbuild-dev.yaml"


COMMIT_ID="$(git rev-parse --short=7 HEAD)"
gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/$REPO/hello-cloudbuild:${COMMIT_ID}" .
rm cloudbuild-dev.yaml
cat > cloudbuild-dev.yaml <<EOF
steps:
  # Step 1: Compile the Go Application
  - name: 'gcr.io/cloud-builders/go'
    env: ['GOPATH=/gopath']
    args: ['build', '-o', 'main', 'main.go']

  # Step 2: Build the Docker image for the Go application
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild-dev:v1.0', '.']

  # Step 3: Push the Docker image to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild-dev:v1.0']

  # Step 4: Apply the production deployment YAML file to the production namespace
  - name: 'gcr.io/cloud-builders/kubectl'
    id: 'Deploy'
    args: ['-n', 'dev', 'apply', '-f', 'dev/deployment.yaml']
    env:
    - 'CLOUDSDK_COMPUTE_REGION=us-central1-a'
    - 'CLOUDSDK_CONTAINER_CLUSTER=hello-cluster'
EOF

export todo=$(gcloud builds list --filter="STATUS: SUCCESS" --format='value(IMAGES)')

cd dev
rm deployment.yaml


cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: development-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dev-app
  template:
    metadata:
      labels:
        app: dev-app
    spec:
      containers:
      - name: dev-container
        image: $todo
        ports:
        - containerPort: 8080
EOF

cd ..

git add .
git commit -m "ah" 
git push -u origin dev

sleep 1

git checkout master

rm cloudbuild.yaml
cat > cloudbuild.yaml << EOF
steps:
  # Step 1: Compile the Go Application
  - name: 'gcr.io/cloud-builders/go'
    id: 'Compile application'
    env: ['GOPATH=/gopath']
    args: ['build', '-o', 'main', 'main.go']

  # Step 2: Build the Docker image for the Go application
  - name: 'gcr.io/cloud-builders/docker'
    id: 'Build Docker image'
    args: ['build', '-t', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v1.0', '.']

  # Step 3: Push the Docker image to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    id: 'Push Docker image'
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v1.0']

  # Step 4: Apply the production deployment YAML file to the production namespace
  - name: 'gcr.io/cloud-builders/kubectl'
    id: 'Deploy'
    args: ['-n', 'prod', 'apply', '-f', 'prod/deployment.yaml']
    env:
    - 'CLOUDSDK_COMPUTE_REGION=us-central1-a'
    - 'CLOUDSDK_CONTAINER_CLUSTER=hello-cluster'
EOF

cd prod
rm deployment.yaml

cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: production-app
  template:
    metadata:
      labels:
        app: production-app
    spec:
      containers:
      - name: production-container
        image: $todo
        ports:
        - containerPort: 8080
EOF

cd ..

git add .
git commit -m "ah" 
git push -u origin master

sleep 1

git checkout dev

rm main.go

cat > main.go << EOF
/**
 * Copyright 2023 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"net/http"
)

func main() {
	http.HandleFunc("/blue", blueHandler)
	http.HandleFunc("/red", redHandler)
	http.ListenAndServe(":8080", nil)
}

func blueHandler(w http.ResponseWriter, r *http.Request) {
	img := image.NewRGBA(image.Rect(0, 0, 100, 100))
	draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{0, 0, 255, 255}}, image.ZP, draw.Src)
	w.Header().Set("Content-Type", "image/png")
	png.Encode(w, img)
}

func redHandler(w http.ResponseWriter, r *http.Request) {
	img := image.NewRGBA(image.Rect(0, 0, 100, 100))
	draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{255, 0, 0, 255}}, image.ZP, draw.Src)
	w.Header().Set("Content-Type", "image/png")
	png.Encode(w, img)
}
EOF


rm cloudbuild.yaml

cat > cloudbuild.yaml << EOF
steps:
  # Step 1: Compile the Go Application
  - name: 'gcr.io/cloud-builders/go'
    id: 'Compile application'
    env: ['GOPATH=/gopath']
    args: ['build', '-o', 'main', 'main.go']

  # Step 2: Build the Docker image for the Go application
  - name: 'gcr.io/cloud-builders/docker'
    id: 'Build Docker image'
    args: ['build', '-t', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v2.0', '.']

  # Step 3: Push the Docker image to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    id: 'Push Docker image'
    args: ['push', 'us-central1-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v2.0']

  # Step 4: Apply the production deployment YAML file to the production namespace
  - name: 'gcr.io/cloud-builders/kubectl'
    id: 'Deploy'
    args: ['-n', 'prod', 'apply', '-f', 'prod/deployment.yaml']
    env:
    - 'CLOUDSDK_COMPUTE_REGION=us-central1-a'
    - 'CLOUDSDK_CONTAINER_CLUSTER=hello-cluster'
EOF

cd dev
rm deployment.yaml

cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: development-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dev-app
  template:
    metadata:
      labels:
        app: dev-app
    spec:
      containers:
      - name: dev-container
        image: us-central1-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v2.0
        ports:
        - containerPort: 8080
EOF

cd ..


git add .
git commit -m "ah" 
git push -u origin dev

sleep 1

git checkout master

rm main.go

cat > main.go << EOF
/**
 * Copyright 2023 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"net/http"
)

func main() {
	http.HandleFunc("/blue", blueHandler)
	http.HandleFunc("/red", redHandler)
	http.ListenAndServe(":8080", nil)
}

func blueHandler(w http.ResponseWriter, r *http.Request) {
	img := image.NewRGBA(image.Rect(0, 0, 100, 100))
	draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{0, 0, 255, 255}}, image.ZP, draw.Src)
	w.Header().Set("Content-Type", "image/png")
	png.Encode(w, img)
}

func redHandler(w http.ResponseWriter, r *http.Request) {
	img := image.NewRGBA(image.Rect(0, 0, 100, 100))
	draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{255, 0, 0, 255}}, image.ZP, draw.Src)
	w.Header().Set("Content-Type", "image/png")
	png.Encode(w, img)
}
EOF


rm cloudbuild.yaml

cat > cloudbuild.yaml << EOF
steps:
  # Step 1: Compile the Go Application
  - name: 'gcr.io/cloud-builders/go'
    id: 'Compile application'
    env: ['GOPATH=/gopath']
    args: ['build', '-o', 'main', 'main.go']

  # Step 2: Build the Docker image for the Go application
  - name: 'gcr.io/cloud-builders/docker'
    id: 'Build Docker image'
    args: ['build', '-t', 'us-central1-docker.pkg.dev/qwiklabs-gcp-02-c6bed03f9368/my-repository/hello-cloudbuild:v2.0', '.']

  # Step 3: Push the Docker image to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    id: 'Push Docker image'
    args: ['push', 'us-central1-docker.pkg.dev/qwiklabs-gcp-02-c6bed03f9368/my-repository/hello-cloudbuild:v2.0']

  # Step 4: Apply the production deployment YAML file to the production namespace
  - name: 'gcr.io/cloud-builders/kubectl'
    id: 'Deploy'
    args: ['-n', 'prod', 'apply', '-f', 'prod/deployment.yaml']
    env:
    - 'CLOUDSDK_COMPUTE_REGION=us-central1-a'
    - 'CLOUDSDK_CONTAINER_CLUSTER=hello-cluster'
EOF

cd prod
rm deployment.yaml

cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: production-app
  template:
    metadata:
      labels:
        app: production-app
    spec:
      containers:
      - name: production-container
        image: us-central1-docker.pkg.dev/$PROJECT_ID/my-repository/hello-cloudbuild:v2.0
        ports:
        - containerPort: 8080
EOF

cd ..

git add .
git commit -m "ah" 
git push -u origin master
