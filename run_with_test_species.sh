#!/bin/bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -profile)
      PROFILE="$2"
      shift # past argument
      shift # past value
      ;;
    --sample_id)
      SAMPLE_ID="$2"
      shift # past argument
      shift # past value
      ;;
    --run_id)
      RUN_ID="$2"
      shift # past argument
      shift # past value
      ;;
    --api_token)
      API_TOKEN="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

echo "PROFILE   = ${PROFILE}"
echo "SAMPLE ID = ${SAMPLE_ID}"
echo "RUN ID    = ${RUN_ID}"
if [ -z "$API_TOKEN" ]
then
    echo "Missing --api_token!"
    exit 1
else
    echo "API_TOKEN set"
fi

nextflow run . -profile $PROFILE --sample_id $SAMPLE_ID --run_id $RUN_ID --api_token $API_TOKEN --species test

