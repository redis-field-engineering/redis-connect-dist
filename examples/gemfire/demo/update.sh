#!/bin/bash

version="${1:-1.12.9}"

container_name="gemfire-$version-$(hostname)"

echo "Updating records in session region.."
docker exec --user root "${container_name}" sh -c "gfsh -e 'connect --locator localhost[10334]' -e 'put --key=('Key1') --value=('UpdatedValue1') --region=/session' -e 'put --key=('Key2') --value=('UpdatedValue2') --region=/session'"

echo "done"