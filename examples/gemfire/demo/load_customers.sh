#!/bin/bash

version="${1:-1.15.1}"

container_name="gemfire-$version-$(hostname)"

echo "Inserting records in session region.."
docker exec --user root "${container_name}" sh -c "gfsh -e 'connect --locator localhost[10334]' -e 'put --key=\"customer1\" --value=(\"name\":\"Jack\",\"age\":35) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer2\" --value=(\"name\":\"Alice\",\"age\":36) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer3\" --value=(\"name\":\"Bob\",\"age\":37) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer4\" --value=(\"name\":\"Carol\",\"age\":38) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer5\" --value=(\"name\":\"David\",\"age\":39) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer6\" --value=(\"name\":\"Eva\",\"age\":40) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer7\" --value=(\"name\":\"Frank\",\"age\":41) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer8\" --value=(\"name\":\"Grace\",\"age\":42) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer9\" --value=(\"name\":\"Henry\",\"age\":43) --region=customer --value-class=redis.gemfire.Customer' -e 'put --key=\"customer10\" --value=(\"name\":\"Ivy\",\"age\":44) --region=customer --value-class=redis.gemfire.Customer'"


echo "done"