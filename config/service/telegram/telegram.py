# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "telethon",
#     "httpx",
# ]
# ///
"""
Forward Telegram channel messages to a Discord webhook.

Uses a Telegram user account (not a bot) so it can read channels you don't own.

First run will prompt for your phone number and auth code.
Set these env vars:

    TELEGRAM_API_ID       - from https://my.telegram.org/apps
    TELEGRAM_API_HASH     - from https://my.telegram.org/apps
    DISCORD_WEBHOOK_URL   - Discord channel webhook URL

Usage:
    uv run forward_to_discord.py
"""

import io
import mimetypes
import os
import sys
import httpx
from telethon import TelegramClient, events

API_ID = os.environ.get("TELEGRAM_API_ID")
API_HASH = os.environ.get("TELEGRAM_API_HASH")
WEBHOOK_URL = os.environ.get("DISCORD_WEBHOOK_URL")

MAX_DISCORD_FILE = 25 * 1024 * 1024  # 25 MB upload limit


async def send_to_discord(
    author: str,
    text: str,
    files: list[tuple[str, bytes]] | None = None,
) -> None:
    payload = {
        "username": author,
        "content": text or "",
    }

    async with httpx.AsyncClient() as http:
        if files:
            multipart_files = []
            for i, (filename, data) in enumerate(files):
                mime = mimetypes.guess_type(filename)[0] or "application/octet-stream"
                multipart_files.append((f"files[{i}]", (filename, data, mime)))

            resp = await http.post(
                WEBHOOK_URL,
                data={"payload_json": __import__("json").dumps(payload)},
                files=multipart_files,
                timeout=30,
            )
        else:
            resp = await http.post(WEBHOOK_URL, json=payload, timeout=10)

    resp.raise_for_status()


async def main() -> None:
    if not API_ID or not API_HASH:
        sys.exit("Set TELEGRAM_API_ID and TELEGRAM_API_HASH from https://my.telegram.org/apps")
    if not WEBHOOK_URL:
        sys.exit("Set DISCORD_WEBHOOK_URL")

    client = TelegramClient("forwarder_session", int(API_ID), API_HASH)
    await client.start()

    # Load dialogs so Telethon receives updates from all joined channels
    await client.get_dialogs()

    @client.on(events.NewMessage(incoming=True))
    async def handler(event):
        if event.is_private:
            return

        msg = event.message
        chat = await event.get_chat()
        author = getattr(chat, "title", "Telegram")
        text = msg.text or ""

        files = []
        if msg.file:
            filename = msg.file.name
            if not filename:
                ext = msg.file.ext or ""
                filename = f"attachment{ext}"

            if msg.file.size and msg.file.size > MAX_DISCORD_FILE:
                text += f"\n[skipped {filename}: {msg.file.size // 1024 // 1024} MB > 25 MB limit]"
            else:
                buf = io.BytesIO()
                await client.download_media(msg, file=buf)
                files.append((filename, buf.getvalue()))

        print(f"[{author}] {text[:80]}{f' +{len(files)} file(s)' if files else ''}")
        try:
            await send_to_discord(author, text, files or None)
        except Exception as e:
            print(f"Discord error: {e}")

    print("Listening for messages... (Ctrl+C to stop)")
    await client.run_until_disconnected()


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
