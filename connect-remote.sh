#!/bin/bash
if [ $# -ne 3 ] || [ "$1" == "-h" ]; then
  echo "Usage: $0 USER@SERVER CONTAINER_NAME NODE_NAME"
  echo
  echo "Creates a local IEx session that is connected to a remote node running under docker"
  echo
  echo "Be patient for it to start - it may take a couple of seconds"
  echo "Once connected, you can type 'Nodes.list' in the IEx session to check your node"
  echo "is connected.  And then ':observer.start' to view your remote node"
  echo
  echo "The following can be set via environment variables:"
  echo " ERLANG_COOKIE - defaults to mycookie.  Must match what your remote node has configured."
  echo " DOCKER_BRIDGE_IP - defaults to 172.17.0.1"
  echo " LOCAL_NODE_NAME - defaults to my-laptop"
  exit
fi

USER_SERVER=$1
CONTAINER=$2
REMOTE_NODE_NAME=$3

: ${DOCKER_BRIDGE_IP:=172.17.0.1}
: ${LOCAL_NODE_NAME:=my-laptop}
: ${ERLANG_COOKIE:=mycookie}

ELIXIR="'$(cat connect_remote.ex)'"

echo -n "Creating tunnel..."
ssh -f -o ExitOnForwardFailure=yes $USER_SERVER \
    -R $DOCKER_BRIDGE_IP:4369:127.0.0.1:4369 \
    -R $DOCKER_BRIDGE_IP:19000:127.0.0.1:19000 "\
  echo 'Sleeping for 1 second to wait for local IEx session' &&
  sleep 1 &&
  echo -n 'Remote: connecting to remote node to local node...' &&
  docker exec $CONTAINER \
    elixir --name temp@127.0.0.1 --cookie $ERLANG_COOKIE \
      -e $ELIXIR $REMOTE_NODE_NAME $LOCAL_NODE_NAME $DOCKER_BRIDGE_IP &&
  sleep 5
"
echo "Done"

echo "Creating local IEx session"
iex --name $LOCAL_NODE_NAME@$DOCKER_BRIDGE_IP \
    --cookie $ERLANG_COOKIE \
    --erl "-kernel inet_dist_listen_min 19000 inet_dist_listen_max 19000"
