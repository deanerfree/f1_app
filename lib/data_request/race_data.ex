defmodule DataRequest.RaceData do
  @moduledoc """
  Module for processing race data from the OpenF1 API.
  """
  require Logger

  alias DataRequest.Types
  alias DataRequest.APIClient

  @doc """
  Gets the meeting and session key for the Bahrain 2025 race
  """
  @spec get_keys() :: {:ok, Types.race_key_info()} | {:error, String.t()}
  def get_keys do
    session_data = APIClient.get_session_data()
    meeting_data = APIClient.get_meeting_data()
    Logger.info("Session data: #{inspect(session_data)}")
    Logger.info("Meeting data: #{inspect(meeting_data)}")

    # Extract the last meeting from meeting_data
    meeting =
      case meeting_data do
        {:ok, meetings} when is_list(meetings) and length(meetings) > 0 ->
          List.last(meetings)

        _ ->
          # Empty map as fallback
          %{}
      end

    case session_data do
      {:ok, session_data} when is_list(session_data) and length(session_data) > 0 ->
        # Extract the meeting_key from the first session
        session_data = Enum.at(session_data, 0)
        Logger.info("Session data found: #{inspect(session_data)}")

        if Map.has_key?(session_data, "meeting_key") do
          Logger.info("Meeting key found: #{session_data["meeting_key"]}")
          Logger.info("Session key found: #{session_data["session_key"]}")

          {:ok,
           %{
             meeting_key: session_data["meeting_key"],
             session_key: session_data["session_key"],
             country_name: meeting["country_name"],
             meeting_official_name: meeting["meeting_official_name"],
             meeting_name: meeting["meeting_name"],
             location: meeting["location"]
           }}
        else
          Logger.error("Session data does not contain meeting_key: #{inspect(session_data)}")
          {:error, "No meeting_key in session data"}
        end

      {:ok, []} ->
        Logger.error("Session data is empty")
        {:error, "No sessions found"}

      err ->
        Logger.error("Failed to get session data: #{inspect(err)}")
        err
    end
  end

  @doc """
  Gets the Race data from the meeting
  """
  @spec get_meeting() :: {:ok, Types.meeting()} | {:error, String.t()}
  def get_meeting do
    case APIClient.get_meeting_data() do
      {:ok, meeting_data} when is_list(meeting_data) and length(meeting_data) > 0 ->
        # Extract the meeting_key from the first session
        meeting = Enum.at(meeting_data, 0)
        Logger.info("Meeting data found: #{inspect(meeting)}")

      {:ok, []} ->
        Logger.error("Meeting data is empty")
        {:error, "No meetings found"}

      err ->
        Logger.error("Failed to get meeting data: #{inspect(err)}")
        err
    end
  end

  @doc """
  Gets information about the driver results if available
  """
  @spec get_results() :: {:ok, Types.race_data()} | {:error, String.t()}
  def get_results do
    case get_keys() do
      {:ok, key_data} ->
        %{
          meeting_key: meeting_key,
          session_key: session_key,
          country_name: country_name,
          meeting_official_name: meeting_official_name,
          meeting_name: meeting_name,
          location: location
        } = key_data

        Logger.info("key: #{inspect(key_data)}")

        case APIClient.get_drivers(meeting_key, session_key) do
          {:ok, drivers} when is_list(drivers) and length(drivers) > 0 ->

            result =
              %{
                country_name: country_name,
                meeting_official_name: meeting_official_name,
                meeting_name: meeting_name,
                location: location,
                results:
                  Enum.map(drivers, fn driver ->
            Logger.info("Drivers data found: #{driver["driver_number"]}")
                    case APIClient.get_position(
                           meeting_key,
                           session_key,
                           driver["driver_number"]
                         ) do
                      {:ok, position_data} ->#when is_list(position_data) and length(position_data) > 0 ->
                        Logger.info("Position data: #{inspect(position_data)}")
                        Logger.info("Driver number: #{driver["driver_number"]}")
                        final_position = List.last(position_data)
                        %{
                          broadcast_name: driver["broadcast_name"],
                          constructor: driver["team_name"],
                          driver_name: driver["full_name"],
                          driver_number: driver["driver_number"],
                          image: driver["headshot_url"],
                          name_acronym: driver["name_acronym"],
                          team_colour: "B6BABD",
                          position: final_position["position"]
                        }

                      {:error, err} ->
                        Logger.error(
                          "Failed to get position data for driver #{driver["driver_number"]}: #{inspect(err)}"
                        )

                        nil
                    end
                  end)
              }

            # Add a return value for the success case
            {:ok, result}

          err ->
            Logger.error("Failed to get drivers data: #{inspect(err)}")
            {:error, "No drivers found"}
        end

      err ->
        Logger.error("Failed to get meeting key: #{inspect(err)}")
        {:error, "No meeting key found"}
    end
  end
end
