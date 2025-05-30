
defmodule DataRequest.Utils do
  @moduledoc """
  Utility functions for the DataRequest application.
  """
  require Logger

  @doc """
  Generates a unique list of maps based on a specified key (returns full maps, unique by key).
  """
  @spec createUniqueList([map()], String.t()) :: [map()]
  def createUniqueList(list, key) do
    Logger.debug("Creating unique list for key: #{key}")
    # Filter out items that do not have the key or have a nil value for the key
    # Logger.debug("Original list length: #{inspect(list)}")
    unique_list = list
    |> Enum.filter(fn item ->
      Map.has_key?(item, key) and not is_nil(item[key])
      item[key]
    end)
    |> Enum.map(fn item -> item[key] end)
    |> Enum.uniq()

    unique_list
  end
end
