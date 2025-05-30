# lib/data_request/router.ex
defmodule DataRequest.Router do
  use Plug.Router
  require Logger

  plug(Plug.Logger)
  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)
    alias DataRequest.Utils, as: Utils
  # conn = fetch_query_params(conn)

  get "/" do

    if conn.query_params == %{} do
      {:ok, races} = DataRequest.RaceData.get_all_search_parameters()
      years_task = Task.async(fn -> Utils.createUniqueList(races, :year) end)
      locations_task = Task.async(fn -> Utils.createUniqueList(races, :location) end)
      countries_task = Task.async(fn -> Utils.createUniqueList(races, :country_name) end)

      years = Task.await(years_task, 5000)
      locations = Task.await(locations_task, 5000)
      countries = Task.await(countries_task, 5000)
      |> Enum.sort()

      Logger.info("Available years: #{inspect(years)}")
      Logger.info("Available locations: #{inspect(locations)}")
      Logger.info("Available countries: #{inspect(countries)}")


      html = generate_init_page(years, countries, locations)
      send_resp(conn, 200, html)
    end

    location = conn.query_params["location"] || nil
    country = conn.query_params["country"] || nil
    year = conn.query_params["year"] || nil

    Logger.info("Received request for #{location} #{country} #{year}")

    race_results_task =
      Task.async(fn ->
        case DataRequest.RaceData.get_results(location, year) do
          {:ok, results} ->
            results

          {:error, reason} ->
            Logger.error("Failed to get results: #{inspect(reason)}")
            nil
        end
      end)

    meeting_event_task =
      Task.async(fn ->
        case DataRequest.APIClient.get_meeting_data(location, year) do
          {:ok, meeting_event} ->
            List.last(meeting_event)

          {:error, reason} ->
            Logger.error("Failed to get meeting event: #{inspect(reason)}")
            nil
        end
      end)

    # Wait for both tasks to complete with timeout
    race_results = Task.await(race_results_task, 10000)
    meeting_event = Task.await(meeting_event_task, 10000)

    # Generate HTML with both datasets
    html = generate_html(race_results, meeting_event)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp generate_init_page(years, countries, locations) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>F1 Data App</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
        p { font-size: 1.2em; }
      </style>
    </head>
    <body>
      <h1>Welcome to the F1 Data Fetch API!</h1>
      <div>
        <h3>Use the following query parameters to look up race results:</h3>
        <form action="/" method="get">
          <label for="year">Year:</label>
          <select id="year" name="year" required>
            <option value="">Select Year</option>
            #{Enum.map(years, fn year -> "<option value=\"#{year}\">#{year}</option>" end) |> Enum.join("\n")}
          </select>
          <br><br>
          <label for="location">Location:</label>
          <select id="location" name="location" required>
            <option value="">Select Location</option>
            #{Enum.map(locations, fn loc -> "<option value=\"#{loc}\">#{loc}</option>" end) |> Enum.join("\n")}
          </select>
          <br><br>
          <button type="submit">Get Results</button>
      </div>
    </body>
    </html>
    """
  end

  defp generate_html(race_data, meeting_event) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>#{meeting_event["meeting_name"]} Results</title>
      <style>
        body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1, h2 { color: #333; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .driver-img { width: 40px; height: 40px; border-radius: 50%; }
        .constructor { font-size: 0.9em; color: #666; }
      </style>
    </head>
    <body>
      <h1>#{meeting_event["meeting_official_name"]}</h1>
      <h2>#{meeting_event["location"]}, #{meeting_event["country_name"]}</h2>

      <table>
        <thead>
          <tr>
            <th>Pos</th>
            <th>Driver</th>
            <th>Number</th>
            <th>Constructor</th>
          </tr>
        </thead>
        <tbody>
          #{generate_results_rows(race_data.results)}
        </tbody>
      </table>
    </body>
    </html>
    """
  end

  defp generate_results_rows(results) do
    results
    |> Enum.sort_by(& &1.position)
    |> Enum.map(fn driver ->
      """
      <tr style="transition: all 0.3s;" onmouseover="this.style.backgroundColor='##{driver.team_colour}20';" onmouseout="this.style.backgroundColor='';">
        <td>#{driver.position}</td>
        <td>
          <img src="#{driver.image}" class="driver-img" alt="#{driver.driver_name}">
          #{driver.driver_name}
        </td>
        <td>#{driver.driver_number}</td>
        <td class="constructor">#{driver.constructor}</td>
      </tr>
      """
    end)
    |> Enum.join("\n")
  end
end
