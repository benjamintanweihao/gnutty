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

    assert HostCache.peers(host_cache) == [servent] 
  end

  test "a host cache saves only unique entries of peers" do
    {:ok, host_cache} = HostCache.start_link
    {:ok, servent_1}  = Servent.start_link
    {:ok, servent_2}  = Servent.start_link

    HostCache.hello(host_cache, servent_1)
    HostCache.hello(host_cache, servent_2)
    HostCache.hello(host_cache, servent_1)

    [servent_1, servent_2] |> Enum.each(fn pid -> 
      assert Enum.member? HostCache.peers(host_cache), pid
    end)

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

    assert Servent.peers(servent_1) == [servent_2]
    assert Servent.peers(servent_2) == [servent_1]
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

    refute Enum.member? HostCache.peers(host_cache), servent_2
  end

end
