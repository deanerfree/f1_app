# F1 Data Application

A simple Elixir application that fetches Formula 1 race data from the OpenF1 API and displays it through a web interface.

## Features

- Fetches race data including drivers, positions, and race metadata
- Displays results in a clean, organized HTML table
- Highlights team colors on row hover
- Simple, lightweight web server using Plug/Cowboy

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/deanerfree/f1_app.git
   cd f1_app
   ```
2. Install dependencies:
   ```bash
   mix deps.get
   mix compile
   ```
3. Start the application:
   ```bash
   mix run --no-halt
   ```
4. Open your web browser and navigate to `http://localhost:8080`.

## Project Structure
```
f1_app/
├── lib/
│   ├── data_request/
│   │   ├── api_client.ex #Fetches data from the OpenF1 API
│   │   ├── router.ex #Handles HTTP requests
│   │   └── race_data.ex #Builds the data
│   │   
│   ├── types/
│   │   └── types.ex #Type file
│   └── application.ex
├── mix.exs
├── mix.lock
└── README.md

```

## Dependencies
- `plug_cowboy`: For the web server
- `jason`: For JSON parsing
- `httpoison`: For making HTTP requests
- `ex_doc`: For documentation generation
- `ex_unit`: For testing

## API Data

This application uses the [OpenF1 API](https://api.openf1.org/) to fetch Formula 1 race data.

## License

[MIT](LICENSE.md)