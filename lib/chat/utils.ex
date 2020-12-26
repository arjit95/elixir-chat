defmodule Chat.Utils do
  @doc """
  Used for processing database reads in batches.
  Useful for pagination of data

  ```elixir
  # Reads messages in batches of 100
  Chat.Utils.batch_ops(fn {skip, limit} ->
    # data fetched from db
    data
  end, 100)
  ```
  """
  @spec batch_ops(term(), number()) :: term()
  def batch_ops(func, batch_limit) do
    {_reads, _skips, total_reads} =
      Stream.unfold({0, batch_limit, []}, fn {skip, limit, current_reads} ->
        reads = func.(skip, limit)
        num_reads = length(reads)

        if num_reads == 0 do
          nil
        else
          {{limit, skip, current_reads}, {num_reads, skip + num_reads, reads ++ current_reads}}
        end
      end)
      |> Enum.to_list()
      |> List.last()

    total_reads
  end
end
