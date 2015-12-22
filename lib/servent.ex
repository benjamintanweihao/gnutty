defmodule Servent do
  use GenServer

  defmodule State do
    defstruct peers: HashSet.new, 
           data_fun: nil, 
           matcher_fun: &String.contains?/2 
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

  def search(pid, peer, search_query) do
    send(pid, {:search, peer, search_query})
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def ping(pid, peer) do
    GenServer.cast(pid, {:ping, peer})
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

  def handle_info({:search, peer, search_query}, state) do
    handle_query(peer, search_query, state)
    {:noreply, state}
  end

  def handle_info({:query_hit, peer, result}, state) do
    send(peer, {:query_hit, self, result})
    {:noreply, state}
  end

  #####################
  # Private Functions #
  #####################

  defp handle_query(peer, search_query, state) do
    %{peers: peers, data_fun: data_fun, matcher_fun: matcher_fun} = state
    data   = data_fun.()
    result = data |> Enum.filter(&(matcher_fun.(&1, search_query)))

    if query_miss?(result) do
      query_peers(peers, peer, search_query)
    else
      send(peer, {:query_hit, self, result})
    end
  end

  defp query_peers(peers, self, search_query) do
    peers |> Enum.each(&(search(&1, self, search_query)))
  end

  defp query_miss?(result) do
    Enum.empty?(result)
  end

end
