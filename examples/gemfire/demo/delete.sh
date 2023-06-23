#!/bin/bash

version="${1:-1.12.9}"

container_name="gemfire-$version-$(hostname)"

echo "Deleting records from session region.."
docker exec --user root "${container_name}" sh -c "gfsh -e 'connect --locator localhost[10334]' -e 'remove --key=('Key7') --region=/session' -e 'remove --key=('Key9') --region=/session'"

echo "done"