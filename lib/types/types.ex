defmodule DataRequest.Types do
  @moduledoc """
  Type definitions for the DataRequest application.
  """
  @type driver_result :: %{
          position: integer(),
          image: String.t(),
          driver_number: integer(),
          broadcast_name: String.t(),
          constructor: String.t(),
          driver_name: String.t(),
          name_acronym: String.t(),
          team_colour: String.t()
        }

  @type race_data :: %{
          location: String.t(),
          country_name: String.t(),
          meeting_official_name: String.t(),
          meeting_name: String.t(),
          results: [driver_result()]
        }

  @type race_key_info :: %{
          meeting_key: integer(),
          session_key: integer(),
          country_name: String.t(),
          meeting_official_name: String.t(),
          meeting_name: String.t(),
          location: String.t()
        }

  @type meeting :: %{
          circuit_key: integer(),
          circuit_short_name: String.t(),
          country_code: String.t(),
          country_key: integer(),
          country_name: String.t(),
          date_start: String.t(),
          gmt_offset: String.t(),
          location: String.t(),
          meeting_code: String.t(),
          meeting_key: integer(),
          meeting_name: String.t(),
          meeting_official_name: String.t(),
          year: integer()
        }

  @type meetings :: [meeting()]

  @type session :: %{
          session_key: integer(),
          session_name: String.t(),
          date_start: String.t(),
          date_end: String.t(),
          gmt_offset: String.t(),
          session_type: String.t(),
          meeting_key: integer(),
          location: String.t(),
          country_key: integer(),
          country_code: String.t(),
          country_name: String.t(),
          circuit_key: integer(),
          circuit_short_name: String.t(),
          year: integer()
        }

  @type sessions :: [session()]

  @type driver :: %{
          session_key: integer(),
          meeting_key: integer(),
          broadcast_name: String.t(),
          country_code: String.t(),
          first_name: String.t(),
          full_name: String.t(),
          headshot_url: String.t(),
          last_name: String.t(),
          driver_number: integer(),
          team_colour: String.t(),
          team_name: String.t(),
          name_acronym: String.t()
        }

  @type drivers :: [driver()]

  @type position :: %{
          session_key: integer(),
          meeting_key: integer(),
          driver_number: integer(),
          date: String.t(),
          position: integer()
        }

  @type positions :: [position()]
end
