WORKSPACE=$1

set -e
set -x

s3fs "$WORKSPACE-dirtydata" /workspace/buckets/upload_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style -o nonempty
s3fs "$WORKSPACE-readyforprocessing" /workspace/buckets/input_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style -o nonempty
s3fs "$WORKSPACE-output" /workspace/buckets/output_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style -o nonempty
s3fs "$WORKSPACE-relatedness" /workspace/buckets/relatedness_bucket -o passwd_file=/workspace/project/s3fs_password_file -o url=https://lrbvkel2wjot.compat.objectstorage.uk-london-1.oraclecloud.com -o use_path_request_style -o nonempty
