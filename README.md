# Connect Remote Elixir Docker

This script allows you to start a local IEx session and connect it to a remotely running Docker node.

## Installation

Just clone this repo onto your local machine.

## Prerequisites

You should ensure that your Elixir and Erlang version installed locally matches that of the docker container that you want to connect to.

### Enable GatewayPorts
By default remote port forwarding (which is used by the script) can only bind to the loopback adapter on the remote host which will not be accessible from a container.  To change this edit `/etc/ssh/sshd_config` on the server and add this line:
```
GatewayPorts clientspecified
```
Ensure there are no other `GatewayPorts` lines in the file.  Next, reload the configuration by executing `sudo service ssh restart`.  (These instructions are for Ubuntu, it might be slightly different on other distributions.)

### Run your container with an Erlang node name and Erlang cookie

The app must set its node name and a Erlang cookie when it starts.

#### Phoenix apps

You will probably be starting your app with something like
```
mix phoenix.server
```

To set the node name and cookie you can change it to this
```
elixir --cookie mycookie --name myapp@127.0.0.1 -S mix phoenix.server
```
Ensure that the IP is this loopback address.

#### EXRM/Distillery

If you created a release you will probably need to change `rel/vm.args` file to set the cookie and node name.

## Usage

Once you have this setup, you should be able to connect to the remote node as follows:

```bash
my-laptop$ ./connect-remote.sh me@myserver.com myapp_container myapp

Creating tunnel...Done
Creating local IEx session
Sleeping for 1 second to wait for local IEx session
Erlang/OTP 19 [erts-8.3] [source] [64-bit] [smp:4:4] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir (1.4.2) - press Ctrl+C to exit (type h() ENTER for help)
iex(my-laptop@172.17.0.1)1> Remote: connecting to remote node to local node...Connected
                                                                                       Done

nil
iex(my-laptop@172.17.0.1)2> Node.list
[:"myapp@127.0.0.1"]
iex(my-laptop@172.17.0.1)3>                
```
You can now switch the IEx session to be on this remote node or start the Observer locally.

The parameters to the `connect-remote.sh` script are:
1. User and hostname of Docker host
2. Name of the Docker container running your app
3. Name of the node (without the 127.0.0.1) in your container that was set with the `elixir --name` parameter.

Other defaults can be overridden if required by environment variables. Run `./connect-remote.sh -h` to get usage.

## How does it work?

It starts a local IEx session and then creates an SSH tunnel and forwards the local Erlang EPMD port and port 19000 (for inter-node communication) to the Docker bridge IP on the remote machine.

It then does a `docker exec` into the running container, creates a second (but temporary) Erlang node in that container, and finally does an RPC to your running app's Erlang node to tell it to connect to your local Erlang node via the forwarded ports.

The SSH tunnel should stay open until the local IEx session is closed.

## Known issues

* While connecting, the formatting of the output from the remote server not print carriage returns correctly. (See example above)
