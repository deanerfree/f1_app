defmodule DataRequest.RaceData do
  @moduledoc """
  Module for processing race data from the OpenF1 API.
  """
  require Logger

  alias DataRequest.Types, as: Types
  alias DataRequest.APIClient

  @doc """
  Gets all the meetings and return a collection of locations
  """
  # @spec get_all_meetings() :: {:ok, [Types.meeting()]} | {:error, String.t()}
  def get_all_search_parameters do
    case APIClient.get_all_meetings() do
      {:ok, meetings} when is_list(meetings) and length(meetings) > 0 ->
        {:ok, meetings}
        locations = Enum.map(meetings, fn meeting ->
          %{
            location: meeting["location"],
            country_name: meeting["country_name"],
            year: meeting["year"],
          }
        end)

        # Logger.info("Meetings found: #{inspect(locations)}")
        {:ok, locations}


      {:ok, []} ->
        Logger.error("No meetings found")
        {:error, "No meetings found"}

      err ->
        Logger.error("Failed to get meetings: #{inspect(err)}")
        err
    end
  end

  @doc """
  Gets the meeting and session key for the Bahrain 2025 race
  """
  @spec get_keys(String.t(), String.t()) :: {:ok, Types.race_key_info()} | {:error, String.t()}
  def get_keys(location, year) do
    session_data = APIClient.get_session_data(location, year)

    case session_data do
      {:ok, session_data} when is_list(session_data) and length(session_data) > 0 ->
        # Extract the meeting_key from the first session
        session_data = Enum.at(session_data, 0)
        # Logger.info("Session data found: #{inspect(session_data)}")

        if Map.has_key?(session_data, "meeting_key") do
          {:ok,
           %{
             meeting_key: session_data["meeting_key"],
             session_key: session_data["session_key"]
             #    country_name: meeting["country_name"],
             #    meeting_official_name: meeting["meeting_official_name"],
             #    meeting_name: meeting["meeting_name"],
             #    location: meeting["location"]
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
  @spec get_meeting(String.t(), String.t()) :: {:ok, Types.meeting()} | {:error, String.t()}
  def get_meeting(location, year) do
    Logger.debug("Fetching meeting data for location: #{location}, year: #{year}")
    case APIClient.get_meeting_data(location, year) do
      {:ok, meeting_data} when is_list(meeting_data) and length(meeting_data) > 0 ->
        # Extract the meeting_key from the first session
        meeting = Enum.at(meeting_data, 0)

        meeting

      # Logger.info("Meeting data found: #{inspect(meeting)}")

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
  @spec get_results(String.t(), String.t()) :: {:ok, Types.race_data()} | {:error, String.t()}
  def get_results(location, year) do
    case get_keys(location, year) do
      {:ok, key_data} ->
        %{
          meeting_key: meeting_key,
          session_key: session_key
        } = key_data

        Logger.info("key: #{inspect(key_data)}")

        case APIClient.get_drivers(meeting_key, session_key) do
          {:ok, drivers} when is_list(drivers) and length(drivers) > 0 ->
            # Create a task for each driver to fetch their position in parallel
            driver_tasks =
              Enum.map(drivers, fn driver ->
                Task.async(fn ->
                  case APIClient.get_position(
                         session_key,
                         meeting_key,
                         driver["driver_number"]
                       ) do
                    {:ok, position_data} ->
                      final_position = List.last(position_data)

                      %{
                        broadcast_name: driver["broadcast_name"],
                        constructor: driver["team_name"],
                        driver_name: driver["full_name"],
                        driver_number: driver["driver_number"],
                        image: driver["headshot_url"],
                        name_acronym: driver["name_acronym"],
                        team_colour: driver["team_colour"],
                        position: final_position["position"]
                      }

                    {:error, err} ->
                      Logger.error(
                        "Failed to get position data for driver #{driver["driver_number"]}: #{inspect(err)}"
                      )

                      nil
                  end
                end)
              end)

            # Wait for all tasks to complete (with a timeout)
            driver_results =
              driver_tasks
              |> Enum.map(fn task -> Task.await(task, 5000) end)
              # Remove any nil results
              |> Enum.filter(&(&1 != nil))

            result = %{results: driver_results}

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
