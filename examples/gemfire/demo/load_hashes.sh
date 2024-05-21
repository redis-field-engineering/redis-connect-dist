#!/bin/bash

version="${1:-1.15.1}"

container_name="gemfire-$version-$(hostname)"

echo "Inserting records in session region.."
docker exec --user root "${container_name}" sh -c "gfsh -e 'connect --locator localhost[10334]' -e 'put --key=\"user1\" --value=(\"name\":\"Jack\",\"age\":35) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user2\" --value=(\"name\":\"Alice\",\"age\":36) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user3\" --value=(\"name\":\"Bob\",\"age\":37) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user4\" --value=(\"name\":\"Carol\",\"age\":38) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user5\" --value=(\"name\":\"David\",\"age\":39) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user6\" --value=(\"name\":\"Eva\",\"age\":40) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user7\" --value=(\"name\":\"Frank\",\"age\":41) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user8\" --value=(\"name\":\"Grace\",\"age\":42) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user9\" --value=(\"name\":\"Henry\",\"age\":43) --region=hash --value-class=java.util.HashMap' -e 'put --key=\"user10\" --value=(\"name\":\"Ivy\",\"age\":44) --region=hash --value-class=java.util.HashMap'"


echo "done"