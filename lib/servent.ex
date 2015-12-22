defmodule Servent do
  use GenServer

  defmodule State do
    defstruct peers: HashSet.new
  end

  #######
  # API #
  #######

  def start_link(state \\ %State{}) do
    GenServer.start_link(__MODULE__, state)
  end

  def peers(pid) do
    GenServer.call(pid, :peers)
  end

  def ping(pid, peer) do
    GenServer.cast(pid, {:ping, peer})
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  #############
  # Callbacks #
  #############

  def handle_call(:peers, _from, state) do
    {:reply, HashSet.to_list(state.peers), state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  # Servent sends a ping
  def handle_cast({:ping, peer}, state) do
    send(peer, {:ping, self})
    {:noreply, state}
  end

  # Servent receives a ping
  def handle_info({:ping, peer}, state) do
    send(peer, {:pong, self})
    Process.monitor(peer)
    new_state = %{state | peers: HashSet.put(state.peers, peer)}
    {:noreply, new_state}
  end

  # Servent receives a pong
  def handle_info({:pong, peer}, state) do
    Process.monitor(peer)
    new_state = %{state | peers: HashSet.put(state.peers, peer)}
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | peers: HashSet.delete(state.peers, pid)}}
  end

  #####################
  # Private Functions #
  #####################

end
