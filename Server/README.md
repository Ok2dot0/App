# Simple Message Server (Python/Flask)

A tiny server that matches the app's contract:
- GET /message → returns one message
- POST /message → accepts a JSON body {"message":"..."} and replies 201 with an echo

Works for:
- Android emulator using `http://10.0.2.2:3000`
- Desktop/web using `http://localhost:3000`

## Run (Windows PowerShell)

1) Create and activate a virtual environment (recommended)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2) Install dependencies

```powershell
pip install -r requirements.txt
```

3) Start the server (bind 0.0.0.0 so the emulator can reach it)

```powershell
python .\app.py
```

Server listens on `http://0.0.0.0:3000`.

## Endpoints

- GET `/message`
  - Accept: `application/json` (default) or `text/plain`
  - 200 JSON: `{ "message": "Hello from server" }`
  - 200 Text: `Hello from server`

- POST `/message`
  - Headers: `Content-Type: application/json`
  - Body: `{ "message": "Hi there" }`
  - 201 JSON: `{ "ok": true, "message": "Hi there" }`

## Notes
- Non-2xx and network errors are surfaced by the app.
- If using Flutter on Android emulator, keep using `10.0.2.2` as host.
