#!/bin/bash

version="${1:-1.12.9}"

container_name="gemfire-$version-$(hostname)"

echo "Inserting records in session region.."
docker exec --user root "${container_name}" sh -c "gfsh -e 'connect --locator localhost[10334]' -e 'put --key=('Key11') --value=('Value11') --region=/session'"

echo "done"