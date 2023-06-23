#!/bin/bash

version="${1:-1.12.9}"

container_name="gemfire-$version-$(hostname)"

echo "Inserting records in session region.."
docker exec --user root "${container_name}" sh -c "gfsh -e 'connect --locator localhost[10334]' -e 'put --key=('Key1') --value=('Value1') --region=/session' -e 'put --key=('Key2') --value=('Value2') --region=/session' -e 'put --key=('Key3') --value=('Value3') --region=/session' -e 'put --key=('Key4') --value=('Value4') --region=/session' -e 'put --key=('Key5') --value=('Value5') --region=/session' -e 'put --key=('Key6') --value=('Value6') --region=/session' -e 'put --key=('Key7') --value=('Value7') --region=/session' -e 'put --key=('Key8') --value=('Value8') --region=/session' -e 'put --key=('Key9') --value=('Value9') --region=/session' -e 'put --key=('Key10') --value=('Value10') --region=/session'"

echo "done"