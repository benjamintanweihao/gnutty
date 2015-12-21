defmodule HostCache do
  use GenServer

  def start_link do
    :random.seed(:os.timestamp)
    GenServer.start_link(__MODULE__, HashSet.new)
  end

  def hello(pid, peer) do
    GenServer.call(pid, {:hello, peer})
  end

  def peers(pid) do
    GenServer.call(pid, :peers)
  end

  def handle_call({:hello, peer}, _from, peers) do
    if Enum.empty?(peers) do
      {:reply, {:welcome, :no_peers}, HashSet.put(peers, peer)}
    else
      random_peer = Enum.random(peers)
      Servent.ping(peer, random_peer)
      {:reply, {:welcome, Enum.random(peers)}, HashSet.put(peers, peer)}
    end
  end

  def handle_call({:hello, peer}, _from, peers) do
    {:reply, {:welcome, :no_peers}, HashSet.put(peers, peer)}
  end

  def handle_call(:peers, _from, peers) do
    {:reply, HashSet.to_list(peers), peers}
  end

end
