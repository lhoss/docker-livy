#!/bin/bash

if [ -z ${HOST+x} ]; then
  export LIBPROCESS_IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)
else
  export LIBPROCESS_IP=$HOST
fi

#new: CMD in Dockerfile starts livy (by default)
#$LIVY_APP_PATH/bin/livy-server $@

echo "entrypoint ENV : $LIVY_APP_PATH=${LIVY_APP_PATH}, $LIVY_HOME=${LIVY_HOME} LIBPROCESS_IP=${LIBPROCESS_IP}"
echo "entrypoint exec: $@"
exec "$@"
