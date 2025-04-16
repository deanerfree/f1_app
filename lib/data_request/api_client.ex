defmodule DataRequest.APIClient do
  @moduledoc """
  Client for making API requests to the OpenF1 API.
  """
  require Logger

  alias DataRequest.Types

  @doc """
  Makes a GET request and parses the JSON response.

  ## Examples

      iex> DataRequest.APIClient.get_json("https://api.openf1.org/v1/sessions?country_name=Bahrain&session_name=Race&year=2025")
      {:ok, [%{"session_name" => "Race", ...}]}

      iex> DataRequest.APIClient.get_json("https://invalid-url")
      {:error, :connection_failed}
  """
  @spec get_json(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_json(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error("Request failed with status code #{status_code}")
        {:error, "Request failed with status code #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @spec get_session_data() :: {:ok, Types.sessions()} | {:error, String.t()}
  def get_session_data do
    url = "https://api.openf1.org/v1/sessions?country_name=Bahrain&session_name=Race&year=2025"
    get_json(url)
  end

  @doc """
    Fetch meeting data
  """
  @spec get_meeting_data() :: {:ok, Types.meetings()} | {:error, String.t()}
  def get_meeting_data do
    url = "https://api.openf1.org/v1/meetings?country_name=Bahrain&year=2025"
    get_json(url)
  end

  @doc """
    Fetch drivers data
  """
  @spec get_drivers(String.t(), String.t()) :: {:ok, Types.drivers()} | {:error, String.t()}
  def get_drivers(meeting, session) do
    url = "https://api.openf1.org/v1/drivers?meeting_key=#{meeting}&session_key=#{session}"
    get_json(url)
  end

  @doc """
    Fetch position data for a specific session
  """
  @spec get_position(integer(), integer(), integer()) ::
          {:ok, Types.positions()} | {:error, String.t()}
  def get_position(session_key, meeting_key, num) do
    url =
      "https://api.openf1.org/v1/position?session_key=#{session_key}&meeting_key=#{meeting_key}&driver_number=#{num}"

    get_json(url)
  end
end
