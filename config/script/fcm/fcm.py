import json
import logging
import os
import subprocess
import sys
import threading
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import NoReturn

logging.basicConfig(
    filename = "/var/log/fcm.log",
    format = "%(asctime)s %(levelname)s %(message)s",
    level = logging.DEBUG,
)

OUTPUT_DIR = "/data/shared/lives"
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
}

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

    # Create output directory
    folder = Path(OUTPUT_DIR) / f"{username}_{dt.strftime('%Y-%m-%d')}_{timestamp}"
    folder.mkdir(parents=True, exist_ok=True)

    # Record the livestream, mux into mp4
    output = folder / f"{timestamp}.mp4"
    log_file = (folder / "instarec.log").open("w")

    env = os.environ.copy()
    env["HOME"] = "/root"  # instarec looks in ~/.config/instarec/credentials.json
    proc = subprocess.Popen(["instarec", username, str(output)], stdout=log_file, stderr=subprocess.STDOUT, env=env)

    # Create metadata.txt
    metadata = folder / "metadata.txt"
    with metadata.open("w") as f:
        f.write(f"{name} @{username} IG Live ({dt.strftime('%-m/%d/%y')})\n")
        f.write(f"https://instagram.com/{username} on {dt.strftime('%b. %-d, %Y at %-I:%M:%S %p UTC')}\n")
        f.write(f"\n\n#iglive #{dt.strftime('%Y')} #unreleased #snippet #leak #{username}\n")

    # Block until recording is complete
    proc.wait()
    log_file.close()
    logging.info(f"{name} (@{username}) has ended their live.")
    send_discord({
        "embeds": [{"title": f"{name} (@{username}) has ended their live."}]
    })

    # TODO: upload to YouTube

def main():
    if len(sys.argv) != 2:
        logging.error("Usage: fcm \"<JSON string>\"")
        sys.exit(1)

    try:
        data = json.loads(sys.argv[1])
        logging.debug(str(data))
    except json.JSONDecodeError as e:
        panic(e)

    if data == None or data.get("anapp") != "Instagram":
        logging.debug("Invalid message")
        return

    # Get notification sender's username
    sender = None
    if extras_str := data.get("anextras"):
        try:
            extras = json.loads(extras_str)
            sender_id = extras.get("com.instagram.android.igns.logging.sender_id")
        except json.JSONDecodeError as e:
            panic(e)

        sender = USERNAMES.get(sender_id)

    if sender == None:
        logging.warning("Missing username")
        return

    # Currently, only detect lives
    match (data.get("antext")):
        case "Live now":
            record(sender, data.get("antitle"), data.get("anwhentime"))
        case _:
            logging.debug("Unhandled message")

def send_discord(payload: dict):
    webhook_path = os.environ.get("WEBHOOK")
    if not webhook_path:
        logging.error("WEBHOOK environment variable not set")
        return

    def send():
        with open(webhook_path) as f:
            webhook_url = f.read().strip()
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(webhook_url, data=data, headers={"Content-Type": "application/json"})
        urllib.request.urlopen(req)

    threading.Thread(target=send, daemon=True).start()

def panic(e: Exception) -> NoReturn:
    logging.error(e)
    sys.exit(1)

if __name__ == "__main__":
    main()
