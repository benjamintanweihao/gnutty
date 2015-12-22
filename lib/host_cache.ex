defmodule HostCache do
  use GenServer

  #######
  # API #
  #######

  @spec start_link :: {:ok, pid}
  def start_link do
    _ = :random.seed(:os.timestamp)
    GenServer.start_link(__MODULE__, HashSet.new)
  end

  @spec hello(pid, pid) :: any
  def hello(pid, peer) do
    GenServer.call(pid, {:hello, peer})
  end

  @spec peers(pid) :: any
  def peers(pid) do
    GenServer.call(pid, :peers)
  end

  #############
  # Callbacks #
  #############

  @spec handle_call({:hello, pid}, any, %{}) :: {:reply, {:welcome, :no_peers | pid} , %{}} 
  def handle_call({:hello, peer}, _from, peers) do
    Process.monitor(peer)
    if Enum.empty?(peers) do
      {:reply, {:welcome, :no_peers}, HashSet.put(peers, peer)}
    else
      random_peer = Enum.random(peers)
      Servent.ping(peer, random_peer)
      {:reply, {:welcome, Enum.random(peers)}, HashSet.put(peers, peer)}
    end
  end

  @spec handle_call(:peers, any, %{}) :: {:reply, pid , %{}} 
  def handle_call(:peers, _from, peers) do
    {:reply, HashSet.to_list(peers), peers}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, peers) do
    {:noreply, HashSet.delete(peers, pid)}
  end

end
