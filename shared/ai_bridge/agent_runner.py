"""Cross-platform task runner for Claude Code and Codex CLI."""

from __future__ import annotations

import argparse
import base64
import ctypes
import json
import platform
import shutil
import subprocess
import sys
import locale
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = Path(__file__).with_name("config.json")
PROMPT_DIR = ROOT / "shared" / "prompts" / "system_tasks"
LOG_DIR = ROOT / "shared" / "local_workspace" / "logs"
ENV_PATH = ROOT / "shared" / "local_workspace" / "env_config" / ".env"
LOCALE_SLANGUAGE = 0x00000002
LOCALE_NAME_MAX_LENGTH = 85


def load_config() -> dict:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def load_dotenv() -> dict[str, str]:
    values: dict[str, str] = {}
    if not ENV_PATH.exists():
        return values
    for raw_line in ENV_PATH.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, value = line.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
            value = value[1:-1]
        values[name.strip()] = value
    return values


def system_locale() -> str:
    if platform.system() == "Windows":
        command = [
            "powershell.exe",
            "-NoProfile",
            "-Command",
            "Add-Type -AssemblyName System.Windows.Forms; "
            "[System.Windows.Forms.InputLanguage]::CurrentInputLanguage.Culture.Name",
        ]
        result = subprocess.run(command, capture_output=True, text=True, check=False)
        input_language = result.stdout.strip()
        if result.returncode == 0 and input_language:
            return input_language
        buffer = ctypes.create_unicode_buffer(85)
        if ctypes.windll.kernel32.GetUserDefaultLocaleName(buffer, len(buffer)):
            return buffer.value
    return locale.getlocale()[0] or "en-US"


def system_language(locale_name: str) -> str:
    if platform.system() == "Windows":
        buffer = ctypes.create_unicode_buffer(LOCALE_NAME_MAX_LENGTH)
        length = ctypes.windll.kernel32.GetLocaleInfoEx(
            locale_name,
            LOCALE_SLANGUAGE,
            buffer,
            len(buffer),
        )
        if length:
            return buffer.value
    return locale_name


def read_clipboard() -> str:
    commands = []
    if platform.system() == "Windows":
        commands = [[
            "powershell.exe",
            "-NoProfile",
            "-Command",
            "[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false); Get-Clipboard -Raw",
        ]]
    elif platform.system() == "Darwin":
        commands = [["pbpaste"]]
    else:
        commands = [["xclip", "-selection", "clipboard", "-o"], ["xsel", "--clipboard", "--output"]]
    for command in commands:
        if shutil.which(command[0]) or Path(command[0]).exists():
            result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
            if result.returncode == 0:
                return result.stdout
    return ""


def write_clipboard(text: str) -> bool:
    if platform.system() == "Windows":
        command = [
            "powershell.exe",
            "-NoProfile",
            "-Command",
            "$value = [Console]::In.ReadToEnd(); "
            "Set-Clipboard -Value ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value)))",
        ]
        encoded = base64.b64encode(text.encode("utf-8")).decode("ascii")
        result = subprocess.run(command, input=encoded, text=True, capture_output=True, check=False)
        return result.returncode == 0
    elif platform.system() == "Darwin":
        command = ["pbcopy"]
    else:
        if shutil.which("xclip"):
            command = ["xclip", "-selection", "clipboard"]
        elif shutil.which("xsel"):
            command = ["xsel", "--clipboard", "--input"]
        else:
            return False
    result = subprocess.run(command, input=text, text=True, encoding="utf-8", capture_output=True, check=False)
    return result.returncode == 0


def confirm(task: str) -> bool:
    message = f"Confirm guarded task '{task}'? [y/N] "
    if platform.system() == "Windows":
        try:
            import ctypes
            result = ctypes.windll.user32.MessageBoxW(0, message, "Macro Orchestrator", 1)
            return result == 1
        except Exception:
            pass
    try:
        return input(message).strip().lower() in {"y", "yes"}
    except EOFError:
        return False


def build_prompt(task: str, language: str, template: str, context: str) -> str:
    target_language = system_language(language)
    prompt = template.replace("{{TARGET_LANG}}", target_language)
    prompt += f"\n\nTarget output language: {target_language} (OS locale {language}).\nTask id: {task}.\n"
    if context.strip():
        prompt += "\nSelected clipboard context:\n---\n" + context + "\n---\n"
    return prompt


def append_log(task: str, language: str, engine: str, status: str, output: str, prompt: str = "") -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).isoformat()
    log_path = LOG_DIR / "agent_runner.log"
    with log_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps({
            "timestamp": timestamp,
            "task": task,
            "language": language,
            "engine": engine,
            "status": status,
            "prompt": prompt[-12000:],
            "output": output[-4000:],
        }, ensure_ascii=False) + "\n")


def run_gemini(prompt: str, model: str, secrets: dict[str, str]) -> tuple[int, str]:
    api_key = secrets.get("GEMINI_API_KEY", "")
    if not api_key:
        return 1, f"GEMINI_API_KEY is missing from {ENV_PATH}."
    endpoint = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        + model
        + ":generateContent?key="
        + urllib.parse.quote(api_key, safe="")
    )
    payload = json.dumps({
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.2},
    }).encode("utf-8")
    request = urllib.request.Request(
        endpoint,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                body = json.loads(response.read().decode("utf-8"))
            parts = body.get("candidates", [{}])[0].get("content", {}).get("parts", [])
            output = "".join(part.get("text", "") for part in parts).strip()
            if not output:
                return 1, "Gemini returned an empty response."
            return 0, output
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="replace")
            if error.code in {429, 500, 502, 503, 504} and attempt < 2:
                time.sleep(2 ** attempt)
                continue
            return error.code, f"Gemini API error: {detail}"
        except (urllib.error.URLError, TimeoutError) as error:
            if attempt < 2:
                time.sleep(2 ** attempt)
                continue
            return 1, f"Gemini connection error: {error}"


def run(args: argparse.Namespace) -> int:
    config = load_config()
    secrets = load_dotenv()
    language = system_locale() if config.get("default_language", "system") == "system" else config["default_language"]
    task = config["tasks"].get(args.task)
    if not task:
        raise SystemExit(f"Unknown task '{args.task}'.")
    if task.get("long_press") and not args.long_press_required and not args.dry_run:
        raise SystemExit(f"Task '{args.task}' requires a mapper-level long-press guard.")
    if task.get("confirm") and not args.dry_run and (args.confirm_popup or not args.no_confirm):
        if not confirm(args.task):
            append_log(args.task, language, config["engine"], "cancelled", "", "")
            return 2
    prompt_path = PROMPT_DIR / task["prompt"]
    prompt = build_prompt(args.task, language, prompt_path.read_text(encoding="utf-8"), read_clipboard())
    if args.dry_run:
        print(prompt)
        return 0

    engine = args.engine or config["engine"]
    engine_config = config["engines"].get(engine)
    if not engine_config:
        raise SystemExit(f"Unknown engine '{engine}'.")
    if engine_config.get("type") == "api":
        return_code, output = run_gemini(prompt, engine_config["model"], secrets)
    else:
        command = engine_config["command"]
        if not shutil.which(command[0]):
            raise SystemExit(f"Engine executable not found: {command[0]}")
        result = subprocess.run(command, input=prompt, capture_output=True, text=True, encoding="utf-8", errors="replace")
        return_code = result.returncode
        output = (result.stdout or result.stderr).strip()
    append_log(args.task, language, engine, "success" if return_code == 0 else "failed", output, prompt)
    if return_code != 0:
        print(output, file=sys.stderr)
        return return_code
    if engine_config.get("output_to_clipboard", True) and output and not write_clipboard(output):
        failure = "AI response succeeded, but writing the response to the clipboard failed."
        append_log(args.task, language, engine, "failed", failure, prompt)
        print(failure, file=sys.stderr)
        return 1
    print(output)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--task", required=True)
    parser.add_argument("--engine", choices=["codex", "claude_code"])
    parser.add_argument("--confirm-popup", action="store_true")
    parser.add_argument("--long-press-required", action="store_true")
    parser.add_argument("--no-confirm", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return run(parser.parse_args())


if __name__ == "__main__":
    raise SystemExit(main())
