defmodule Servent do
  use GenServer

  defmodule State do
    defstruct peers: HashSet.new, data_fun: nil, matcher_fun: &String.contains?/2 
    @type t :: %State{peers: %{}, data_fun: (() -> [char_list]), matcher_fun: ((char_list, char_list) -> boolean)}
  end

  @type on_start :: {:ok, pid} | {:error, {:already_started, pid} | term}

  #######
  # API #
  #######

  @spec start_link(State.t) :: on_start
  def start_link(state \\ %State{}) do
    GenServer.start_link(__MODULE__, state)
  end

  @spec peers(pid) :: any
  def peers(pid) do
    GenServer.call(pid, :peers)
  end

  @spec search(pid, pid, [char_list]) :: any
  def search(pid, peer, search_query) do
    send(pid, {:search, peer, search_query})
  end

  @spec stop(pid) :: any
  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  @spec ping(pid, pid) :: any
  def ping(pid, peer) do
    GenServer.cast(pid, {:ping, peer})
  end

  #############
  # Callbacks #
  #############

  @spec handle_call(:peers, any, State.t) :: {:reply, list(pid), State.t}
  def handle_call(:peers, _from, state) do
    {:reply, HashSet.to_list(state.peers), state}
  end

  @spec handle_call(:stop, any, State.t) :: {:stop, :normal, :ok, State.t}
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  # Servent sends a ping
  @spec handle_cast({:ping, pid}, State.t) :: {:noreply, State.t}
  def handle_cast({:ping, peer}, state) do
    send(peer, {:ping, self})
    {:noreply, state}
  end

  # Servent receives a ping
  @spec handle_info({:ping, pid}, State.t) :: {:noreply, State.t}
  def handle_info({:ping, peer}, state) do
    send(peer, {:pong, self})
    Process.monitor(peer)
    new_state = %{state | peers: HashSet.put(state.peers, peer)}
    {:noreply, new_state}
  end

  # Servent receives a pong
  @spec handle_info({:pong, pid}, State.t) :: {:noreply, State.t}
  def handle_info({:pong, peer}, state) do
    Process.monitor(peer)
    new_state = %{state | peers: HashSet.put(state.peers, peer)}
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, %{state | peers: HashSet.delete(state.peers, pid)}}
  end

  @spec handle_info({:search, pid, char_list}, State.t) :: {:noreply, State.t}
  def handle_info({:search, peer, search_query}, state) do
    handle_query(peer, search_query, state)
    {:noreply, state}
  end

  @spec handle_info({:query_hit, pid, list}, State.t) :: {:noreply, State.t}
  def handle_info({:query_hit, peer, result}, state) do
    send(peer, {:query_hit, self, result})
    {:noreply, state}
  end

  #####################
  # Private Functions #
  #####################

  @spec query_peers(pid, char_list, State.t) :: :ok
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

  @spec query_peers([pid], pid, char_list) :: any
  defp query_peers(peers, self, search_query) do
    peers |> Enum.each(&(search(&1, self, search_query)))
  end

  @spec query_miss?(list(char_list)) :: boolean
  defp query_miss?(result) do
    Enum.empty?(result)
  end

end
