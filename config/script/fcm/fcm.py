#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["instagrapi", "instarec"]
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

logging.basicConfig(
    format="%(levelname)s %(message)s",
    level=logging.DEBUG,
)

HOST = "0.0.0.0"
PORT = 9000
OUTPUT_DIR = "/data/shared/lives"
WEBHOOK_PATH = "/run/secrets/webhook"

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
    if extras_str := data.get("anextras"):
        try:
            extras = json.loads(extras_str)
            sender_id = extras.get("com.instagram.android.igns.logging.sender_id")
        except json.JSONDecodeError as e:
            logging.error(f"Invalid extras JSON: {e}")
            return

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
        "embeds": [{"title": f"{name} (@{username}) has gone live!"}],
        "components": [{
            "type": 1,
            "components": [{
                "type": 2,
                "style": 5,
                "label": "Watch",
                "url": f"https://instagram.com/{username}/live",
            }],
        }],
    })

    dt = datetime.fromtimestamp(int(timestamp) / 1000, tz=timezone.utc)

    folder = Path(OUTPUT_DIR) / f"{username}_{dt.strftime('%Y-%m-%d')}_{timestamp}"
    folder.mkdir(parents=True, exist_ok=True)

    output = folder / f"{timestamp}.mp4"
    log_file = (folder / "instarec.log").open("w")

    env = os.environ.copy()
    env["HOME"] = "/root"
    proc = subprocess.Popen(["instarec", username, str(output)], stdout=log_file, stderr=subprocess.STDOUT, env=env)

    metadata = folder / "metadata.txt"
    with metadata.open("w") as f:
        f.write(f"{name} @{username} IG Live ({dt.strftime('%-m/%d/%y')})\n")
        f.write(f"https://instagram.com/{username} on {dt.strftime('%b. %-d, %Y at %-I:%M:%S %p UTC')}\n")
        f.write(f"\n\n#iglive #{dt.strftime('%Y')} #unreleased #snippet #leak #{username}\n")

    proc.wait()
    log_file.close()
    logging.info(f"{name} (@{username}) has ended their live.")
    send_discord({
        "embeds": [{"title": f"{name} (@{username}) has ended their live."}]
    })


def send_discord(payload: dict):
    if not os.path.exists(WEBHOOK_PATH):
        logging.error(f"Webhook file not found: {WEBHOOK_PATH}")
        return

    def send():
        with open(WEBHOOK_PATH) as f:
            webhook_url = f.read().strip()
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(webhook_url, data=data, headers={"Content-Type": "application/json"})
        urllib.request.urlopen(req)

    threading.Thread(target=send, daemon=True).start()


def main():
    logging.info(f"Starting server on {HOST}:{PORT}")
    server = HTTPServer((HOST, PORT), Handler)
    server.serve_forever()


if __name__ == "__main__":
    main()
