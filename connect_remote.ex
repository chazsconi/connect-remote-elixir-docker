# Args are:
# remote_node_name (string)
# local_node_name (e.g. my-laptop)
# Docker bridge ip (normally 172.17.0.1)
# N.B. No single quotes can be in this file as this is used to escape it when passing to elixir
[remote_node_name, local_node_name, docker_bridge_ip] = System.argv()

pid =
  Node.spawn_link(:"#{remote_node_name}@127.0.0.1", fn ->
    result = Node.connect(:"#{local_node_name}@#{docker_bridge_ip}")
    receive do
      {:ping, parent} -> send parent, {:result, result}
    end
  end)
send pid, {:ping, self()}
receive do
  {:result, true}  -> IO.puts "Connected"
  {:result, false} -> IO.puts "Failed to connect"
after
  5000 -> IO.puts "Could not spawn link to remote node"
end
IO.puts "Done"
