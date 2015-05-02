defmodule PhoenixPubSubPostgres.Server do
  use GenServer
  alias Phoenix.PubSub.Local

  @moduledoc """
  `Phoenix.PubSub` adapter for Postgres

  See `Phoenix.PubSub.Postgres` for details and configuration options.
  """

  @reconnect_after_ms 5_000
  @postgres_msg_vsn 1

  @doc """
  Starts the server
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Dict.fetch!(opts, :name))
  end

  @doc """
  Broadcasts message to Postgres. To be only called from {:perform, {m, f, a}}
  response to clients
  """
  def broadcast(namespace, pool_name, postgres_msg) do
    :poolboy.transaction pool_name, fn worker_pid ->
      bin_msg = :erlang.term_to_binary(postgres_msg) |> :base64.encode
      case GenServer.call(worker_pid, :conn) do
        {:ok, conn_pid} ->
          case Postgrex.Connection.query(conn_pid, "NOTIFY $1, $2", [namespace, bin_msg]) do
            {:error, reason} -> {:error, reason}
            {:error, kind, reason, stack} ->
              :erlang.raise(kind, reason, stack)
            _ -> :ok
          end

        {:error, reason} -> {:error, reason}
      end
    end
  end

  def init(opts) do
    Process.flag(:trap_exit, true)
    send(self, :establish_conn)
    {:ok, %{local_name: Keyword.fetch!(opts, :local_name),
            pool_name: Keyword.fetch!(opts, :pool_name),
            namespace: postgres_namespace,
            postgrex_pid: nil,
            postgrex_ref: nil,
            status: :disconnected,
            opts: opts}}
  end

  def handle_call({:broadcast, from_pid, topic, msg}, _from, state) do
    postgres_msg = {@postgres_msg_vsn, from_pid, topic, msg}
    resp = {:perform, {__MODULE__, :broadcast, [state.namespace, state.pool_name, postgres_msg]}}
    {:reply, resp, state}
  end
  
  def handle_call({:subscribe, pid, topic, opts}, _from, state) do
    response = {:perform, {Local, :subscribe, [state.local_name, pid, topic, opts]}}
    {:reply, response, state}
  end

  def handle_call({:unsubscribe, pid, topic}, _from, state) do
    response = {:perform, {Local, :unsubscribe, [state.local_name, pid, topic]}}
    {:reply, response, state}
  end

  def handle_info(:establish_conn, state) do
    case Postgrex.Connection.start_link(state.opts) do
      {:ok, postgrex_pid} -> establish_success(postgrex_pid, state)
      _error          -> establish_failed(state)
    end
  end

  def handle_info({:notification, pid, ref, namespace, encoded_message} = message, state) do
    {_vsn, from_pid, topic, msg} = :base64.decode(encoded_message) |> :erlang.binary_to_term
    Local.broadcast(state.local_name, from_pid, topic, msg)
    {:noreply, state}
  end

  defp postgres_namespace(), do: "phoenix_pubsub_postgres"

  defp establish_failed(state) do
    :timer.send_after(@reconnect_after_ms, :establish_conn)
    {:noreply, %{state | status: :disconnected}}
  end
  defp establish_success(postgrex_pid, state) do
    {:ok, ref} = Postgrex.Connection.listen(postgrex_pid, state.namespace)
    {:noreply, %{state | postgrex_pid: postgrex_pid,
                         postgrex_ref: ref,
                         status: :connected}}
  end
end
