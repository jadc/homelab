import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import NoReturn

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

def panic(e: Exception) -> NoReturn:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)

def record(username: str, name: str, timestamp: str):
    print(f"[{timestamp}] {name} (@{username}) has gone live!")

    # Create output directory
    folder = Path(OUTPUT_DIR) / f"{timestamp}_{username}"
    folder.mkdir(parents=True, exist_ok=True)

    # Record the livestream, mux into mp4
    output = folder / f"{timestamp}.mp4"
    proc = subprocess.Popen(["instarec", username, str(output)])

    # Create metadata.txt
    metadata = folder / "metadata.txt"
    dt = datetime.fromtimestamp(int(timestamp) / 1000, tz=timezone.utc)
    with metadata.open("w") as f:
        f.write(f"{name} @{username} IG Live ({dt.strftime('%-m/%d/%y')})\n")
        f.write(f"https://instagram.com/{username} on {dt.strftime('%b. %-d, %Y at %-I:%M:%S %p UTC')}\n")
        f.write(f"\n\n#iglive #{dt.strftime('%Y')} #unreleased #snippet #leak #{username}\n")

    # Block until recording is complete
    proc.wait()

    # TODO: upload to YouTube
    print(f"Completed recording of {name} (@{username})")

def main():
    if len(sys.argv) != 2:
        print("Usage: fcm \"<JSON string>\"", file=sys.stderr)
        sys.exit(1)

    try:
        data = json.loads(sys.argv[1])
    except json.JSONDecodeError as e:
        panic(e)

    if data.get("anapp") != "Instagram":
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
        return

    # Currently, only detect lives
    match (data.get("antext")):
        case "Live now":
            record(sender, data.get("antitle"), data.get("anwhentime"))
        case _:
            print("Unhandled message: " + str(data))

if __name__ == "__main__":
    main()
