# Deploy using Helm charts

## Prerequisites

- [System Requirements](system-requirements.md)
- K8s installation on single or multi node must be done as pre-requisite to continue the following deployment. Note: The kubernetes cluster is set up with `kubeadm`, `kubectl` and `kubelet` packages on single and multi nodes with `v1.30.2`.
  Refer to tutorials online to setup kubernetes cluster on the web with host OS as ubuntu 22.04 and/or ubuntu 24.04.
- For helm installation, refer to [helm website](https://helm.sh/docs/intro/install/)


## Setup the application

> **Note**: The following instructions assume Kubernetes is already running in the host system with helm package manager installed.

1. Clone the **edge-ai-suites** repository and change into industrial-edge-insights-vision directory. The directory contains the utility scripts required in the instructions that follows.
    ```sh
    git clone https://github.com/open-edge-platform/edge-ai-suites.git
    cd manufacturing-ai-suite/industrial-edge-insights-vision
    ```
2. Set app specific values.yaml file.
    ```sh
    cp helm/values_worker_safety.yaml helm/values.yaml
    ```
3.  Edit the HOST_IP, proxy and other environment variables in `values.yaml` as follows
    ```yaml
    env:        
        HOST_IP: <HOST_IP>   # host IP address
        http_proxy: <http proxy> # proxy details if behind proxy
        https_proxy: <https proxy>
        SAMPLE_APP: worker-safety # application directory
    webrtcturnserver:
        username: <username>  # WebRTC credentials e.g. intel1234
        password: <password>
    ```
4.  Install pre-requisites. Run with sudo if needed.
    ```sh
    ./setup.sh helm
    ```
    This sets up application pre-requisites, download artifacts, sets executable permissions for scripts etc. Downloaded resource directories.

## Deploy the application

5.  Install the helm chart
    ```sh
    helm install app-deploy helm -n apps --create-namespace
    ```
6.  Copy the resources such as video and model from local directory to the to the `dlstreamer-pipeline-server` pod to make them available for application while launching pipelines.
    ```sh
    # Below is an example for Worker safety. Please adjust the source path of models and videos appropriately for other sample applications.
    
    POD_NAME=$(kubectl get pods -n apps -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep deployment-dlstreamer-pipeline-server | head -n 1)

    kubectl cp resources/worker-safety/videos/Safety_Full_Hat_and_Vest.mp4 $POD_NAME:/home/pipeline-server/resources/videos/ -c dlstreamer-pipeline-server -n apps
 
    kubectl cp resources/worker-safety/models/* $POD_NAME:/home/pipeline-server/resources/models/ -c dlstreamer-pipeline-server -n apps
    ```
7.  Fetch the list of pipeline loaded available to launch
    ```sh
    ./sample_list.sh
    ```
    This lists the pipeline loaded in DLStreamer Pipeline Server.
    
    Output:
    ```sh
    # Example output for Worker Safety
    Environment variables loaded from [WORKDIR]/manufacturing-ai-suite/industrial-edge-insights-vision/.env
    Running sample app: worker-safety
    Checking status of dlstreamer-pipeline-server...
    Server reachable. HTTP Status Code: 200
    Loaded pipelines:
    [
        ...
        {
            "description": "DL Streamer Pipeline Server pipeline",
            "name": "user_defined_pipelines",
            "parameters": {
            "properties": {
                "detection-properties": {
                "element": {
                    "format": "element-properties",
                    "name": "detection"
                }
                }
            },
            "type": "object"
            },
            "type": "GStreamer",
            "version": "worker_safety"
        }
        ...
    ]
    ```
8.  Start the sample application with a pipeline.
    ```sh
    ./sample_start.sh -p worker_safety
    ```
    This command would look for the payload for the pipeline specified in `-p` argument above, inside the `payload.json` file and launch the a pipeline instance in DLStreamer Pipeline Server. Refer to the table, to learn about different options available. 
    
    Output:
    ```sh
    # Example output for Worker Safety
    Environment variables loaded from [WORKDIR]/manufacturing-ai-suite/industrial-edge-insights-vision/.env
    Running sample app: worker-safety
    Checking status of dlstreamer-pipeline-server...
    Server reachable. HTTP Status Code: 200
    Loading payload from [WORKDIR]/manufacturing-ai-suite/industrial-edge-insights-vision/helm/apps/worker-safety/payload.json
    Payload loaded successfully.
    Starting pipeline: worker_safety
    Launching pipeline: worker_safety
    Extracting payload for pipeline: worker_safety
    Found 1 payload(s) for pipeline: worker_safety
    Payload for pipeline 'worker_safety' {"source":{"uri":"file:///home/pipeline-server/resources/videos/Safety_Full_Hat_and_Vest.mp4","type":"uri"},"destination":{"frame":{"type":"webrtc","peer-id":"worker_safety"}},"parameters":{"detection-properties":{"model":"/home/pipeline-server/resources/models/worker-safety/deployment/detection_1/model/model.xml","device":"CPU"}}}
    Posting payload to REST server at http://<HOST_IP>:30107/pipelines/user_defined_pipelines/worker_safety
    Payload for pipeline 'worker_safety' posted successfully. Response: "74bebe7a5d1211f08ab0da88aa49c01e"
    ```
    >NOTE- This would start the pipeline. You can view the inference stream on WebRTC by opening a browser and navigating to http://<HOST_IP>:31111/worker_safety/ for Pallet Defect Detection.

9.  Get status of pipeline instance(s) running.
    ```sh
    ./sample_status.sh
    ```
    This command lists status of pipeline instances launched during the lifetime of sample application.
    
    Output:
    ```sh
    # Example output for Worker Safety
    Environment variables loaded from [WORKDIR]/manufacturing-ai-suite/industrial-edge-insights-vision/.env
    Running sample app: worker-safety
    [
    {
        "avg_fps": 30.036955894826452,
        "elapsed_time": 3.096184492111206,
        "id": "784b87b45d1511f08ab0da88aa49c01e",
        "message": "",
        "start_time": 1752100724.3075056,
        "state": "RUNNING"
    }
    ]
    ```

10.  Stop pipeline instance.
    ```sh
    ./sample_stop.sh
    ```
    This command will stop all instances that are currently in `RUNNING` state and respond with the last status.
    
    Output:
    ```sh
    # Example output for Worker Safety
    No pipelines specified. Stopping all pipeline instances
    Environment variables loaded from [WORKDIR]/manufacturing-ai-suite/industrial-edge-insights-vision/.env
    Running sample app: worker-safety
    Checking status of dlstreamer-pipeline-server...
    Server reachable. HTTP Status Code: 200
    Instance list fetched successfully. HTTP Status Code: 200
    Found 1 running pipeline instances.
    Stopping pipeline instance with ID: 784b87b45d1511f08ab0da88aa49c01e
    Pipeline instance with ID '784b87b45d1511f08ab0da88aa49c01e' stopped successfully. Response: {
        "avg_fps": 29.985911953641363,
        "elapsed_time": 37.45091152191162,
        "id": "784b87b45d1511f08ab0da88aa49c01e",
        "message": "",
        "start_time": 1752100724.3075056,
        "state": "RUNNING"
    }
    ```
    If you wish to stop a specific instance, you can provide it with an `--id` argument to the command.    
    For example, `./sample_stop.sh --id 784b87b45d1511f08ab0da88aa49c01e`

11.  Uninstall the helm chart.
     ```sh
     helm uninstall app-deploy -n apps
     ```
    