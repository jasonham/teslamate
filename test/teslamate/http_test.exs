defmodule TeslaMate.HTTPTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  setup do
    on_exit(fn ->
      System.delete_env("NOMINATIM_PROXY")
      System.delete_env("NOMINATIM_HOST")
    end)

    :ok
  end

  test "no env -> nominatim has only size: 3" do
    System.delete_env("NOMINATIM_PROXY")
    System.delete_env("NOMINATIM_HOST")
    pools = TeslaMate.HTTP.pools()
    assert pools["https://nominatim.openstreetmap.org"] == [size: 3]
  end

  test "custom NOMINATIM_HOST -> uses custom host" do
    System.put_env("NOMINATIM_HOST", "http://custom-nominatim:8080")
    pools = TeslaMate.HTTP.pools()

    assert pools["http://custom-nominatim:8080"] == [size: 3]
    refute Map.has_key?(pools, "https://nominatim.openstreetmap.org")
  end

  test "valid http proxy -> nominatim has conn_opts" do
    System.put_env("NOMINATIM_PROXY", "http://127.0.0.1:7890")
    System.delete_env("NOMINATIM_HOST")
    pools = TeslaMate.HTTP.pools()

    assert pools["https://nominatim.openstreetmap.org"] ==
             [size: 3, conn_opts: [proxy: {:http, "127.0.0.1", 7890, []}]]
  end

  test "invalid scheme -> fallback to no proxy and logs warning" do
    log =
      capture_log(fn ->
        System.put_env("NOMINATIM_PROXY", "socks5://127.0.0.1:1080")
        System.delete_env("NOMINATIM_HOST")
        pools = TeslaMate.HTTP.pools()
        assert pools["https://nominatim.openstreetmap.org"] == [size: 3]
      end)

    assert log =~ "unsupported scheme"
    assert log =~ "fallback: no proxy"
  end
end
