#
# A function that will set up a tunnel to a port of a docker container. This is useful for connecting to a
# database running in a container, for example.
#

function tunnel_container () {
   local container=$1
   local port=${2:-3306}
   local network=
   if [[ -z $container || $container == -h || $container == --help ]]; then
      echo 'USE: tunnel_container <container> [port]' >&2
      return
   elif ! network=$(docker container inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{break}}{{end}}' "$container") > /dev/null 2>&1; then
      echo "Container $container does not exist." >&2
      return
   elif [[ -z $network ]]; then
      echo "Could not find network for $container." >&2
      return
   fi
   echo "Connecting you to $container port $port on the $network network. Press ctrl-c when done..."
   docker run --rm --network="$network" -p "$port:$port" alpine/socat "TCP-LISTEN:$port,fork" "TCP:$container:$port"
}
