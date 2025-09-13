from flask import Flask, request, jsonify, make_response
from flask_cors import CORS
import sqlite3

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests (useful for Flutter web)


# Initialize SQLite database
def init_db():
    with sqlite3.connect("messages.db") as conn:
        cursor = conn.cursor()
        # Messages table (legacy/demo)
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT NOT NULL
            )
            """
        )
        # Single-row counter table
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS counter (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                value INTEGER NOT NULL
            )
            """
        )
        # Ensure exactly one counter row exists
        cursor.execute("SELECT COUNT(*) FROM counter")
        count = cursor.fetchone()[0]
        if count == 0:
            cursor.execute("INSERT INTO counter (id, value) VALUES (1, 0)")
        conn.commit()

init_db()

# if db file is empty, insert a default message
with sqlite3.connect("messages.db") as conn:
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM messages")
    if cursor.fetchone()[0] == 0:
        cursor.execute("INSERT INTO messages (content) VALUES (?)", ("Hello from Flask!",))
        conn.commit()

cursor = sqlite3.connect("messages.db").cursor()
cursor.execute("SELECT content FROM messages ORDER BY id DESC LIMIT 1")
row = cursor.fetchone()
message = row[0] if row else ""
print("Initial message:", message)

# ---- Counter endpoints ----
def get_db_connection():
    return sqlite3.connect("messages.db", timeout=5, isolation_level=None)


@app.get("/counter")
def get_counter():
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM counter WHERE id = 1")
        row = cursor.fetchone()
        value = int(row[0]) if row else 0
    return jsonify({"value": value}), 200


@app.post("/counter")
def post_counter():
    """Update counter with either absolute value or delta.
    Body options:
      {"value": <int>} -> set to exact value
      {"delta": <int>} -> increment by delta (can be negative)
    Returns: {"value": <int>}
    """
    data = request.get_json(silent=True) or {}
    if not isinstance(data, dict):
        return jsonify({"error": "Invalid JSON body"}), 400

    set_value = data.get("value")
    delta = data.get("delta")

    if set_value is None and delta is None:
        return jsonify({"error": "Provide either 'value' or 'delta'"}), 400

    with get_db_connection() as conn:
        cursor = conn.cursor()
        if set_value is not None:
            try:
                new_value = int(set_value)
            except (TypeError, ValueError):
                return jsonify({"error": "'value' must be an integer"}), 400
            cursor.execute("UPDATE counter SET value = ? WHERE id = 1", (new_value,))
        else:
            try:
                d = int(delta)
            except (TypeError, ValueError):
                return jsonify({"error": "'delta' must be an integer"}), 400
            # Atomic update
            cursor.execute("UPDATE counter SET value = value + ? WHERE id = 1", (d,))
            cursor.execute("SELECT value FROM counter WHERE id = 1")
            new_value = int(cursor.fetchone()[0])

    return jsonify({"value": new_value}), 200

@app.get("/message")
def get_message():
    """Return a greeting in JSON by default; text/plain if explicitly requested."""
    accept = (request.headers.get("Accept") or "").lower()

    # Prefer JSON unless client explicitly prefers only text/plain
    wants_text = "text/plain" in accept and "application/json" not in accept

    if wants_text:
        resp = make_response(message, 200)
        resp.headers["Content-Type"] = "text/plain; charset=utf-8"
        return resp

    # Default JSON response
    return jsonify({"message": message}), 200


@app.post("/message")
def post_message():
    """Accept a JSON body {"message": "..."} and return 201 with echo."""
    data = request.get_json(silent=True)
    if not isinstance(data, dict) or "message" not in data:
        print("Invalid payload:", data)
        return jsonify({
            "error": "Invalid payload. Expected JSON body like {\"message\": \"Hi there\"}."
        }), 400
    print("Received message:", data["message"])
    global message
    message = data["message"]  # Use direct access since we already validated "message" exists
    # Save to database
    with sqlite3.connect("messages.db") as conn:
        cursor = conn.cursor()
        cursor.execute("INSERT INTO messages (content) VALUES (?)", (message,))
        conn.commit()
    return jsonify({"ok": True, "message": message}), 201


if __name__ == "__main__":
    # Bind to all interfaces so Android emulator (10.0.2.2) can reach the host
    app.run(host="0.0.0.0", port=3000)
    #on exit, close the db connection
    cursor.close()
