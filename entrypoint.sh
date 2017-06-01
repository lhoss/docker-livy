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

# Note: the upload folder is not really required assuming custom jar hdfs URLs work (req. spark 'cluster'mode !)
echo "dynamically fixing (mounted) folder permissions to user:group=${LIVY_USER}:${LIVY_GROUP}"
sudo chown -R ${LIVY_USER}:${LIVY_GROUP} ${LIVY_HOME}/conf ${LIVY_HOME}/upload ${LIVY_HOME}/logs
sudo chmod -R g+w                        ${LIVY_HOME}/conf ${LIVY_HOME}/upload ${LIVY_HOME}/logs

# ready to exec/start livy
exec "$@"
