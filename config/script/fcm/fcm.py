#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["instagrapi", "instarec", "aiohttp-socks", "google-auth-oauthlib", "google-auth-httplib2", "google-api-python-client"]
# ///

import json
import logging
import os
import subprocess
import threading
import urllib.request
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import google.oauth2.credentials
import googleapiclient.discovery
import googleapiclient.http

logging.basicConfig(
    format="%(levelname)s %(message)s",
    level=logging.DEBUG,
)

HOST = "0.0.0.0"
PORT = 9000
OUTPUT_DIR = "/data/shared/lives"
WEBHOOK_PATH = "/run/secrets/webhook"
YOUTUBE_TOKEN_PATH = "/run/secrets/youtube"

USERNAMES = {
    "279519379": "playboicarti",
    "14584624": "pierrebourne",
    "3620523324": "praiseche",
    "62345435174": "xaiversobased",
    "213003800": "workingondying",
    "35332145323": "bedroque00",
    "34186617956": "1onearm",
    "13833573763": "skai",
    "77858229546": "perupujols",
    #"": "opium_00pium",
    "6439958169": "wegonebeok",
    #"": "sexisdeath",
    "45747447988": "osamason",
    "1500042633": "lancey",
    "48776620712": "prettifun",
    "4034718421": "2hollis",
    "33790412": "liluzivert",
    "3240154114": "wakeupf1lthy",
    #"": "yeat",
    "14212987178": "kencarson",
    #"": "prodlucian",
    "28109464": "destroylonely",
    #"": "__outtatown__",
    #"": "homixidebeno5",
    #"": "ye",
    #"": "hardrock4l",
    #"": "homixide55555",
    #"": "_artdealer_",
    #"": "joy_divizn",
    #"": "homixidemeechie5",
    #"": "fakemink",
    #"": "sk8star",
    #"": "diorvsyou",
    #"": "thuggerthugger1",
    #"": "lilbaby",
    #"": "champagnepapi",
    #"": "nba_youngboy",
    #"": "lildurk",
    #"": "trilobourne",
    #"": "21savage",
    #"": "youngnudy",
    #"": "metroboomin",
    #"": "future",
    #"": "travisscott",
}


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/fcm":
            self.send_response(404)
            self.end_headers()
            return

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")

        self.send_response(200)
        self.end_headers()

        threading.Thread(target=handle_request, args=(body,), daemon=True).start()

    def log_message(self, format, *args):
        logging.debug(f"{self.address_string()} - {format % args}")


def handle_request(body: str):
    try:
        data = json.loads(body)
        logging.debug(str(data))
    except json.JSONDecodeError as e:
        logging.error(f"Invalid JSON: {e}")
        return

    if data is None or data.get("anapp") != "Instagram":
        logging.debug("Invalid message")
        return

    sender = None
    if sender_id := data.get("sender_id"):
        sender = USERNAMES.get(sender_id)

    if sender is None:
        logging.warning("Missing username")
        return

    match data.get("antext"):
        case "Live now":
            record(sender, data.get("antitle"), data.get("anwhentime"))
        case _:
            logging.debug("Unhandled message")


def record(username: str, name: str, timestamp: str):
    logging.info(f"{name} (@{username}) has gone live!")
    send_discord({
        "embeds": [{"description": f"{name} ([@{username}](https://instagram.com/{username})) has gone live!", "color": 0x57F287}],
    })

    dt = datetime.fromtimestamp(int(timestamp) / 1000, tz=timezone.utc)

    folder = Path(OUTPUT_DIR) / f"{username}_{dt.strftime('%Y-%m-%d')}_{timestamp}"
    folder.mkdir(parents=True, exist_ok=True)

    output = folder / f"{timestamp}.mp4"
    log_file = (folder / "instarec.log").open("w")

    env = os.environ.copy()
    env["HOME"] = "/root"
    proc = subprocess.Popen(["instarec", username, str(output)], stdout=log_file, stderr=subprocess.STDOUT, env=env)

    metadata = {
        "snippet": {
            "categoryId": "22",
            "title": f"{name} @{username} IG Live ({dt.strftime('%-m/%d/%y')})",
            "description": f"https://instagram.com/{username} on {dt.strftime('%b. %-d, %Y at %-I:%M:%S %p UTC')}",
            "tags": ["iglive", dt.strftime("%Y"), "unreleased", "snippet", "leak", username],
        },
        "status": {
            "privacyStatus": "private",
        },
    }

    with (folder / "metadata.json").open("w") as f:
        json.dump(metadata, f, indent=2)

    proc.wait()
    log_file.close()
    logging.info(f"{name} (@{username}) has ended their live.")
    send_discord({
        "embeds": [{"description": f"{name} ([@{username}](https://instagram.com/{username})) has ended their live.", "color": 0xED4245}]
    })

    upload_youtube(str(output), metadata)

def send_discord(payload: dict):
    def send():
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(webhook_url, data=data, headers={
            "Content-Type": "application/json",
            "User-Agent": "fcm/1.0",
        })
        urllib.request.urlopen(req)

    threading.Thread(target=send, daemon=True).start()


def upload_youtube(video_path: str, request_body: dict):
    with open(YOUTUBE_TOKEN_PATH) as f:
        token_data = json.load(f)

    credentials = google.oauth2.credentials.Credentials(
        token=token_data["token"],
        refresh_token=token_data["refresh_token"],
        token_uri=token_data["token_uri"],
        client_id=token_data["client_id"],
        client_secret=token_data["client_secret"],
    )

    youtube = googleapiclient.discovery.build("youtube", "v3", credentials=credentials)

    request = youtube.videos().insert(
        part="snippet,status",
        body=request_body,
        media_body=googleapiclient.http.MediaFileUpload(video_path, chunksize=-1, resumable=True),
    )

    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            logging.info(f"YouTube upload {int(status.progress() * 100)}%")

    logging.info(f"Video uploaded to YouTube with ID: {response['id']}")
    send_discord({
        "embeds": [{"description": f"[Uploaded to YouTube](https://youtube.com/watch?v={response['id']})", "color": 0x5865F2}]
    })

def main():
    global webhook_url
    with open(WEBHOOK_PATH) as f:
        webhook_url = f.read().strip()
    logging.info(f"Webhook: {webhook_url}")
    logging.info(f"Starting server on {HOST}:{PORT}")
    server = HTTPServer((HOST, PORT), Handler)
    server.serve_forever()


if __name__ == "__main__":
    main()
