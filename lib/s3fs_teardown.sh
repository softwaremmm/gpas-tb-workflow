#!/usr/bin/env bash

#Intentionally not using `set -e` so it tries everything

#Make sure the buckets are unmounted
umount /workspace/buckets/upload_bucket
umount /workspace/buckets/input_bucket
umount /workspace/buckets/output_bucket
umount /workspace/buckets/relatedness_bucket

# Clear up the password file now it's not needed
rm s3fs_password_file