#!/bin/bash

version="${1:-1.15.1}"

container_name="gemfire-$version-$(hostname)"

echo "Inserting records in session region.."
docker exec --user root "${container_name}" sh -c "gfsh -e 'connect --locator localhost[10334]' -e 'put --key=('customer1') --value='{\"name\":\"Jack Ryan\",\"age\":41}' --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=('customer2') --value='{\"name\":\"Emily Clarke\",\"age\":35}' --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=('customer3') --value='{\"name\":\"Michael Brown\",\"age\":29}' --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=('customer4') --value='{\"name\":\"Sarah Miller\",\"age\":22}' --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=('customer5') --value='{\"name\":\"Daniel Lee\",\"age\":47}' --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=('customer6') --value='{\"name\":\"Laura Wilson\",\"age\":30}' --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=('customer7') --value='{\"name\":\"James Smith\",\"age\":50}' --region=customer --value-class=redis.gemfire.Customer'"


echo "done"