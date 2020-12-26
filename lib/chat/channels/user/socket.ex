defmodule Chat.Channels.User.Socket do
  @behaviour :cowboy_websocket

  alias Chat.Channels.User

  def init(req, _state) do
    {:cowboy_websocket, req, %{"users" => [], "groups" => []}}
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_handle({type, "PING"}, state) do
    {:reply, {type, "PING"}, state}
  end

  def websocket_handle({:text, message}, state) do
    websocket_handle({:json, Poison.decode!(message)}, state)
  end

  use User.Auth
  use User.Connections
  use User.Monitor
  use User.Message
  use User.Groups
  use User.RTC

  # async task completion
  def websocket_info({_ref, :ok}, state) do
    {:ok, state}
  end

  def websocket_info({:EXIT, ref, :normal}, state) do
    websocket_info({ref, :ok}, state)
  end

  def websocket_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:ok, state}
  end

  def websocket_info(any, state) do
    IO.inspect(any)
    {:stop, state}
  end

  # stop websocket session on getting unknown request
  def websocket_handle(any, state) do
    IO.inspect(any)
    {:stop, state}
  end
end
