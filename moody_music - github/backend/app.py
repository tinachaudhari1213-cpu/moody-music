
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
import os
import requests
import re
from youtube_config import YOUTUBE_API_KEY

app = Flask(__name__)
CORS(app)


# =========================
# Email and Password Checks
# =========================

def is_valid_email(email):
    if not isinstance(email, str):
        return False

    return bool(re.fullmatch(
        r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
        email.strip()
    ))


def is_valid_password(password):
    if not isinstance(password, str) or len(password) < 8:
        return False

    return (
        any(ch.isalpha() for ch in password)
        and any(ch.isdigit() for ch in password)
    )


# =========================
# MySQL Database Connection
# =========================

def get_db_connection():
    return mysql.connector.connect(
        host="localhost",
        user="your_database_username",
        password="your_database_password",
        database="replace_with_your_secret_key"
    )


# =========================
# Home
# =========================

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "Moody Music Backend is Running!"
    })


# =========================
# Test Database
# =========================





@app.route("/test-db", methods=["GET"])
def test_db():
    print("TEST DB ROUTE CALLED", flush=True)

    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("SELECT COUNT(*) FROM songs")
        count = cursor.fetchone()[0]

        return jsonify({
            "success": True,
            "songs_count": count
        })

    except Exception as e:
        print("ACTUAL ERROR:", repr(e), flush=True)
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500

    finally:
        if cursor is not None:
            cursor.close()

        if connection is not None and connection.is_connected():
            connection.close()

# =========================
# Get All Songs
# =========================

@app.route("/songs", methods=["GET"])
def get_songs():
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT id, title, artist, mood, file_path
            FROM songs
            ORDER BY
                mood,
                CASE
                    WHEN id IN (
                        58,59,60,61,62,
                        78,79,80,81,82,
                        118,119,120,121,122,
                        138,139,140,141,142,
                        158,159,160,161,162,
                        178,179,180,181,182,
                        198,199,200,201,202
                    ) THEN 1
                    ELSE 0
                END,
                id
        """)

        songs = cursor.fetchall()
        print("SONGS API COUNT:", len(songs))
        return jsonify(songs)

    except Exception:
        app.logger.exception("GET SONGS ERROR")
        return jsonify({
            "success": False,
            "message": "Unable to load songs."
        }), 500

    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


# =========================
# Play Music Files
# =========================

MUSIC_FOLDER = os.path.abspath(
    os.path.join(
        os.path.dirname(__file__),
        "..",
        "assets",
        "songs"
    )
)


@app.route("/music/<path:filename>", methods=["GET"])
def play_music(filename):
    return send_from_directory(MUSIC_FOLDER, filename)


# =========================
# Register User
# =========================

@app.route("/register", methods=["POST"])
def register():
    connection = None
    cursor = None

    try:
        data = request.get_json(silent=True) or {}

        name = data.get("name")
        email = data.get("email")
        password = data.get("password")

        if not all(
            isinstance(value, str)
            for value in (name, email, password)
        ):
            return jsonify({
                "success": False,
                "message": "Name, email and password must be text."
            }), 400

        name = name.strip()
        email = email.strip().lower()

        if not name or not email or not password:
            return jsonify({
                "success": False,
                "message": "All fields are required."
            }), 400

        if not is_valid_email(email):
            return jsonify({
                "success": False,
                "message": "Enter a valid email address."
            }), 400

        if not is_valid_password(password):
            return jsonify({
                "success": False,
                "message": (
                    "Password must be at least 8 characters "
                    "and contain a letter and a number."
                )
            }), 400

        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            "SELECT id FROM users WHERE email = %s",
            (email,)
        )

        if cursor.fetchone():
            return jsonify({
                "success": False,
                "message": "Email already registered."
            }), 409

        hashed_password = generate_password_hash(password)

        cursor.execute("""
            INSERT INTO users (name, email, password)
            VALUES (%s, %s, %s)
        """, (name, email, hashed_password))

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Registration successful."
        }), 201

    except Exception:
        if connection is not None:
            connection.rollback()

        app.logger.exception("REGISTER ERROR")
        return jsonify({
            "success": False,
            "message": "Registration failed. Check the backend terminal."
        }), 500

    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


# =========================
# Login User
# =========================

@app.route("/login", methods=["POST"])
def login():
    connection = None
    cursor = None

    try:
        data = request.get_json(silent=True) or {}

        email = str(data.get("email", "")).strip().lower()
        password = str(data.get("password", ""))

        if not email or not password:
            return jsonify({
                "success": False,
                "message": "Email and password are required."
            }), 400

        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT id, name, email, password
            FROM users
            WHERE email = %s
        """, (email,))

        user = cursor.fetchone()

        if not user:
            return jsonify({
                "success": False,
                "message": "Invalid email or password."
            }), 401

        # Verify the stored password hash
        if not check_password_hash(user["password"], password):
            return jsonify({
                "success": False,
                "message": "Invalid email or password."
            }), 401

        return jsonify({
            "success": True,
            "message": "Login successful.",
            "user_id": user["id"],
            "username": user["name"],
            "email": user["email"]
        }), 200

    except Exception:
        app.logger.exception("LOGIN ERROR")
        return jsonify({
            "success": False,
            "message": "Login failed. Check the Python backend terminal."
        }), 500

    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


# =========================
# Add Favorite
# =========================

@app.route("/favorites", methods=["POST"])
def add_favorite():
    connection = None
    cursor = None

    try:
        data = request.get_json(silent=True) or {}
        user_id = data.get("user_id")
        song_id = data.get("song_id")

        if not user_id or not song_id:
            return jsonify({
                "success": False,
                "message": "user_id and song_id are required."
            }), 400

        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("""
            SELECT id FROM favorites
            WHERE user_id = %s AND song_id = %s
        """, (user_id, song_id))

        if cursor.fetchone():
            return jsonify({
                "success": False,
                "message": "Song already in favorites."
            }), 409

        cursor.execute("""
            INSERT INTO favorites (user_id, song_id)
            VALUES (%s, %s)
        """, (user_id, song_id))

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Song added to favorites."
        }), 201

    except Exception:
        if connection is not None:
            connection.rollback()

        app.logger.exception("ADD FAVORITE ERROR")
        return jsonify({
            "success": False,
            "message": "Unable to add favorite."
        }), 500

    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


# =========================
# Get Favorites
# =========================

@app.route("/favorites/<int:user_id>", methods=["GET"])
def get_favorites(user_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT
                songs.id,
                songs.title,
                songs.artist,
                songs.mood,
                songs.file_path
            FROM favorites
            INNER JOIN songs ON favorites.song_id = songs.id
            WHERE favorites.user_id = %s
            ORDER BY favorites.created_at DESC
        """, (user_id,))

        return jsonify(cursor.fetchall())

    except Exception:
        app.logger.exception("GET FAVORITES ERROR")
        return jsonify({
            "success": False,
            "message": "Unable to load favorites."
        }), 500

    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


# =========================
# Add Listening History
# =========================

@app.route("/history", methods=["POST"])
def add_history():
    connection = None
    cursor = None

    try:
        data = request.get_json(silent=True) or {}
        user_id = data.get("user_id")
        song_id = data.get("song_id")

        if not user_id or not song_id:
            return jsonify({
                "success": False,
                "message": "user_id and song_id are required."
            }), 400

        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("""
            INSERT INTO listening_history (user_id, song_id)
            VALUES (%s, %s)
        """, (user_id, song_id))

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Song added to history."
        }), 201

    except Exception:
        if connection is not None:
            connection.rollback()

        app.logger.exception("ADD HISTORY ERROR")
        return jsonify({
            "success": False,
            "message": "Unable to save listening history."
        }), 500

    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


# =========================
# Get Listening History
# =========================

@app.route("/history/<int:user_id>", methods=["GET"])
def get_history(user_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute("""
            SELECT
                songs.id,
                songs.title,
                songs.artist,
                songs.mood,
                songs.file_path,
                listening_history.played_at
            FROM listening_history
            INNER JOIN songs
                ON listening_history.song_id = songs.id
            WHERE listening_history.user_id = %s
            ORDER BY listening_history.played_at DESC
        """, (user_id,))

        return jsonify(cursor.fetchall())

    except Exception:
        app.logger.exception("GET HISTORY ERROR")
        return jsonify({
            "success": False,
            "message": "Unable to load listening history."
        }), 500

    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


# =========================
# Remove Favorite
# =========================

@app.route(
    "/favorites/<int:user_id>/<int:song_id>",
    methods=["DELETE"]
)
def remove_favorite(user_id, song_id):
    connection = None
    cursor = None

    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        cursor.execute("""
            DELETE FROM favorites
            WHERE user_id = %s AND song_id = %s
        """, (user_id, song_id))

        connection.commit()
        deleted_rows = cursor.rowcount

        if deleted_rows == 0:
            return jsonify({
                "success": False,
                "message": "Favorite not found."
            }), 404

        return jsonify({
            "success": True,
            "message": "Song removed from favorites."
        }), 200

    except Exception:
        if connection is not None:
            connection.rollback()

        app.logger.exception("REMOVE FAVORITE ERROR")
        return jsonify({
            "success": False,
            "message": "Unable to remove favorite."
        }), 500

    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


# =========================
# YouTube Search
# =========================

@app.route("/youtube-search", methods=["GET"])
def youtube_search():
    query = request.args.get("q", "").strip()

    if not query:
        return jsonify({
            "success": False,
            "message": "Search query is required."
        }), 400

    if not YOUTUBE_API_KEY:
        return jsonify({
            "success": False,
            "message": "YouTube API key is not configured."
        }), 500

    url = "https://www.googleapis.com/youtube/v3/search"

    params = {
        "part": "snippet",
        "q": query,
        "type": "video",
        "videoCategoryId": "10",
        "maxResults": 10,
        "key": YOUTUBE_API_KEY
    }

    try:
        response = requests.get(
            url,
            params=params,
            timeout=10
        )

        data = response.json()

        if response.status_code != 200:
            message = data.get("error", {}).get(
                "message",
                "YouTube search failed."
            )

            return jsonify({
                "success": False,
                "message": message
            }), response.status_code

        results = []

        for item in data.get("items", []):
            video_id = item.get("id", {}).get("videoId")
            snippet = item.get("snippet", {})

            if not video_id:
                continue

            results.append({
                "video_id": video_id,
                "title": snippet.get("title", ""),
                "channel": snippet.get("channelTitle", ""),
                "thumbnail": snippet.get(
                    "thumbnails", {}
                ).get("high", {}).get("url", "")
            })

        return jsonify({
            "success": True,
            "results": results
        })

    except requests.exceptions.RequestException:
        app.logger.exception("YOUTUBE SEARCH ERROR")
        return jsonify({
            "success": False,
            "message": "Unable to connect to YouTube."
        }), 500


# =========================
# Run Flask Server
# =========================

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
