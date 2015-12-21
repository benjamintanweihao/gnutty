defmodule Servent do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, HashSet.new)
  end

  def peers(pid) do
    GenServer.call(pid, :peers)
  end

  def ping(pid, peer) do
    GenServer.cast(pid, {:ping, peer})
  end

  def handle_call(:peers, _from, peers) do
    {:reply, HashSet.to_list(peers), peers}
  end

  def handle_cast({:ping, peer}, peers) do
    send(peer, {:ping, self})
    {:noreply, peers} 
  end

  def handle_info({:ping, peer}, peers) do
    send(peer, {:pong, self})
    {:noreply, HashSet.put(peers, peer)}
  end

  def handle_info({:pong, peer}, peers) do
    {:noreply, HashSet.put(peers, peer)}
  end

end
