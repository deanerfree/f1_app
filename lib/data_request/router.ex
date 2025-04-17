# lib/data_request/router.ex
defmodule DataRequest.Router do
  use Plug.Router
  require Logger

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/" do
    # Create tasks to run API calls in parallel
    race_results_task =
      Task.async(fn ->
        case DataRequest.RaceData.get_results() do
          {:ok, results} ->
            results

          {:error, reason} ->
            Logger.error("Failed to get results: #{inspect(reason)}")
            nil
        end
      end)

    meeting_event_task =
      Task.async(fn ->
        case DataRequest.APIClient.get_meeting_data() do
          {:ok, meeting_event} ->
            List.last(meeting_event)

          {:error, reason} ->
            Logger.error("Failed to get meeting event: #{inspect(reason)}")
            nil
        end
      end)

    # Wait for both tasks to complete with timeout
    race_results = Task.await(race_results_task, 5000)
    meeting_event = Task.await(meeting_event_task, 5000)

    # Generate HTML with both datasets
    html = generate_html(race_results, meeting_event)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
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
