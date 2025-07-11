#!/bin/bash

# Download artifacts for a specific sample application
#   by calling respective app's install.sh script
SCRIPT_DIR=$(dirname $(readlink -f "$0"))
MODEL_URL="https://github.com/open-edge-platform/edge-ai-suites/raw/9b679287cb6650619b4d1dd01f993ae793f8ec04/manufacturing-ai-suite/industrial-edge-insights-vision/pallet_defect_detection.zip"
VIDEO_URL="https://github.com/open-edge-platform/edge-ai-suites/raw/9da6eb59431eb7edbc5491e8d6ee37d347bebcbb/manufacturing-ai-suite/pallet-defect-detection/resources/videos/warehouse.avi"

err() {
    echo "ERROR: $1" >&2
}

unzip_compressed_file() {
    local zip_file=$1
    local target_dir=$2
    if [ ! -f "$zip_file" ]; then
        err "Zip file '$zip_file' does not exist."
        return 1
    fi
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi
    echo "Unzipping $zip_file to $target_dir..."
    if unzip -q "$zip_file" -d "$target_dir"; then
        echo "Unzipped successfully."
    else
        err "Failed to unzip $zip_file."
        return 1
    fi
}

download_artifacts() {
    local app_name=$1
    echo "$SCRIPT_DIR"
    if [ ! -d "$SCRIPT_DIR" ]; then
        err "Application directory '$SCRIPT_DIR' does not exist."
        return 1
    fi
    # Download model artifacts if not already present
    LOCAL_MODEL_DIR="$SCRIPT_DIR/../../../resources/$app_name/models/$app_name"
    if [ ! -d $LOCAL_MODEL_DIR ]; then
        # create the models directory if it does not exist

        if ! mkdir -p $LOCAL_MODEL_DIR; then
            err "Failed to create models directory for $app_name."
            return 1
        fi
        echo "Downloading model artifacts for $app_name..."
        # echo "Model XML: $MODEL_XML_URL"
        echo "Model URL: $MODEL_URL"
        # Download model XML and BIN files
        if curl -L "$MODEL_URL" -o "$LOCAL_MODEL_DIR/$(basename $MODEL_URL)"; then
            echo "Model zip for $app_name downloaded successfully."
            # Unzip the downloaded model file
            if unzip_compressed_file "$LOCAL_MODEL_DIR/$(basename $MODEL_URL)" "$LOCAL_MODEL_DIR"; then
                echo "Model artifacts for $app_name unzipped successfully."
                # remove the zip file after unzipping
                rm -f "$LOCAL_MODEL_DIR/$(basename $MODEL_URL)"
            fi
        else
            err "Failed to download model for $app_name."
            return 1
        fi
    else
        echo "Model artifacts for $app_name already exist."
    fi

    # Download video artifacts if not already present
    LOCAL_VIDEO_DIR="$SCRIPT_DIR/../../../resources/$app_name/videos"
    if [ ! -d $LOCAL_VIDEO_DIR ]; then
        # create the videos directory if it does not exist
        if ! mkdir -p $LOCAL_VIDEO_DIR; then
            err "Failed to create videos directory for $app_name."
            return 1
        fi
        echo "Downloading video artifacts for $app_name..."
        if ! curl -L "$VIDEO_URL" -o "$LOCAL_VIDEO_DIR/$(basename $VIDEO_URL)"; then
            err "Failed to download video for $app_name."
            return 1
        fi
        echo "Video artifacts for $app_name downloaded successfully."
    else
        echo "Video artifacts for $app_name already exist."
    fi
    return 0

}

download_artifacts "anomaly-detection"