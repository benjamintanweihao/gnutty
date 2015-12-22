defmodule GnuttyTest do
  use ExUnit.Case, async: true
  doctest Gnutty

  test "an empty host cache replies with {:welcome, :no_peers} when it receives :hello" do
    {:ok, host_cache} = HostCache.start_link
    {:ok, servent}    = Servent.start_link

    assert HostCache.hello(host_cache, servent) == {:welcome, :no_peers}
  end

  test "a host cache saves the pid of a peer" do
    {:ok, host_cache} = HostCache.start_link
    {:ok, servent}    = Servent.start_link

    HostCache.hello(host_cache, servent)

    assert servent in HostCache.peers(host_cache)
  end

  test "a host cache saves only unique entries of peers" do
    {:ok, host_cache} = HostCache.start_link
    {:ok, servent_1}  = Servent.start_link
    {:ok, servent_2}  = Servent.start_link

    HostCache.hello(host_cache, servent_1)
    HostCache.hello(host_cache, servent_2)
    HostCache.hello(host_cache, servent_1)

    peers = HostCache.peers(host_cache)
  
    assert servent_1 in peers
    assert servent_2 in peers
  end

  # TODO (QC): need to check that pid is never itself!
  test "a host cache responds with {:welcome, pid} when not empty" do
    {:ok, host_cache} = HostCache.start_link
    {:ok, servent_1}  = Servent.start_link
    {:ok, servent_2}  = Servent.start_link

    HostCache.hello(host_cache, servent_1)
    reply = HostCache.hello(host_cache, servent_2)

    assert reply == {:welcome, servent_1}
  end

  test "a servent adds to its peer list after ping-pong handshaking is done" do
    {:ok, host_cache} = HostCache.start_link
    {:ok, servent_1}  = Servent.start_link
    {:ok, servent_2}  = Servent.start_link

    HostCache.hello(host_cache, servent_1)
    HostCache.hello(host_cache, servent_2)

    assert servent_2 in Servent.peers(servent_1)
    assert servent_1 in Servent.peers(servent_2)
  end
  
  test "a servent removes a peer if that peer becomes unavailable" do
    {:ok, host_cache} = HostCache.start_link
    {:ok, servent_1}  = Servent.start_link
    {:ok, servent_2}  = Servent.start_link

    HostCache.hello(host_cache, servent_1)
    HostCache.hello(host_cache, servent_2)
    Servent.stop(servent_2)

    assert Servent.peers(servent_1) == []
  end

  test "a host cache removes a peer if that peer becomes unavailable" do
    {:ok, host_cache} = HostCache.start_link
    {:ok, servent_1}  = Servent.start_link
    {:ok, servent_2}  = Servent.start_link

    HostCache.hello(host_cache, servent_1)
    HostCache.hello(host_cache, servent_2)
    Servent.stop(servent_2)

    refute servent_2 in HostCache.peers(host_cache)
  end

  test "a servent responds to a {:search, query} with a :query_hit if a match is found" do
    data_fun       = fn -> ["Joe", "Robert", "Mike"] end
    matcher_fun    = fn(element, query) -> String.contains?(element, query) end
    state          = %Servent.State{data_fun: data_fun, matcher_fun: matcher_fun}
    {:ok, servent} = Servent.start_link(state) 

    Servent.search(servent, self, "Ro")
    assert_receive {:query_hit, servent, ["Robert"]}
  end

  test "a servent forwards to another peer if a match is not found" do
    {:ok, host_cache} = HostCache.start_link
    state_1           = %Servent.State{data_fun: fn -> [] end}
    {:ok, servent_1}  = Servent.start_link(state_1) 
    state_2           = %Servent.State{data_fun: fn -> ["Joe", "Robert", "Mike"] end}
    {:ok, servent_2}  = Servent.start_link(state_2) 

    HostCache.hello(host_cache, servent_1)
    HostCache.hello(host_cache, servent_2)

    Servent.search(servent_1, self, "Jo")
    assert_receive {:query_hit, servent_2, ["Joe"]}
  end

end
