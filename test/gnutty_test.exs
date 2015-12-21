defmodule GnuttyTest do
  use ExUnit.Case
  doctest Gnutty

  test "an empty host cache replies with {:welcome, :no_peers} when it receives :hello" do
    {:ok, host_cache} = HostCache.start_link

    send(host_cache, {self, :hello})

    assert_receive {:welcome, :no_peers}
  end

end
