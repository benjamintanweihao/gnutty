defmodule HostCache do

  def start_link do
    pid = spawn_link(__MODULE__, :loop, [HashSet.new])
    {:ok, pid}
  end

  def loop(peers) do
    receive do
      {who, :hello} ->
        peers = HashSet.put(peers, who)
        send(who, {:welcome, :no_peers})
    end
    loop(peers)
  end

end
