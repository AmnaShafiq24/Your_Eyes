from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_functions.params import SecretParam
from firebase_admin import initialize_app
import base64
import json
import requests

set_global_options(max_instances=10)
initialize_app()

OPENAI_API_KEY = SecretParam("OPENAI_API_KEY")
OPENAI_ENDPOINT = "https://api.openai.com/v1/chat/completions"

# Compact but complete: covers task, PKR color cues (biggest accuracy lever
# for worn/angled/partly-covered notes), produce handling, and the exact
# output schema. Kept short on purpose — shorter prompts process faster.
SYSTEM_PROMPT_TEMPLATE = """
You are a visual assistant for a blind user. You will be given a single photo captured from their phone camera. Your job is to identify what is in the image and describe it in a way that is fast to listen to via text-to-speech.

PRIORITY ORDER (check in this order, report only what applies):
1. Pakistani currency notes — if any are visible, identify the denomination(s) (e.g., Rs. 10, 20, 50, 75, 100, 500, 1000, 5000). If multiple notes are visible, state each denomination and the total. If a note is visible but you cannot confidently read its value, say "currency note detected, denomination unclear."
2. Fruits or vegetables — if visible, name each type. If quantity is obvious and relevant (e.g., "3 bananas"), include it; otherwise just name them.
3. If neither currency nor produce is present, briefly describe the main object(s) or scene in the image and say no currency or fruit, vegetable identified.

RESPONSE RULES:
- Respond in one short sentence, sometimes two if multiple distinct items are present.
- Do NOT describe background, lighting, colors, textures, brand names, or camera quality unless it's the only way to identify the item.
- Do NOT hedge with phrases like "it appears to be" or "I can see" — state it directly.
- Do NOT add greetings, disclaimers, or offers to help further.
- If the image is blurry, too dark, or nothing identifiable is in frame, respond only with: "Image unclear, please try again."
- If you are not reasonably confident about an identification, say so briefly rather than guessing (e.g., "Unidentified note" or "Unidentified item") rather than fabricating a value or name.
- Never output markdown, lists, or formatting symbols — output must be plain spoken text only, since it will be read aloud.
- Keep total response under 20 words whenever possible.

OUTPUT FORMAT: Plain text only, one to two short sentences, nothing else.





Reply with ONLY this JSON, nothing else:
{{"category":"currency|produce|unknown","spoken_text":string,"detail":string,
"confidence":number,"needs_retake":boolean,"denomination":string|null,
"denominations":[string],"labels":[string]}}
"""

LANGUAGE_INSTRUCTIONS = {
    "en": "English",
    "ur": "Urdu (Urdu script, natural spoken Urdu — not transliterated)",
}


@https_fn.on_request(secrets=[OPENAI_API_KEY])
def recognizeImage(req: https_fn.Request) -> https_fn.Response:
    if req.method == "OPTIONS":
        return https_fn.Response(
            "",
            status=204,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Max-Age": "3600",
            },
        )

    cors_headers = {"Access-Control-Allow-Origin": "*"}

    try:
        data = req.get_json()
        image_base64 = data.get("image")
        language_code = data.get("language", "en")

        if not image_base64:
            return https_fn.Response(
                json.dumps({"error": "No image provided"}),
                status=400,
                content_type="application/json",
                headers=cors_headers,
            )

        # Strip a data URL prefix if the client included one
        if image_base64.startswith("data:"):
            image_base64 = image_base64.split(",", 1)[1]

        language_instruction = LANGUAGE_INSTRUCTIONS.get(language_code, LANGUAGE_INSTRUCTIONS["en"])
        system_prompt = SYSTEM_PROMPT_TEMPLATE.format(language_instruction=language_instruction)

        openai_payload = {
            "model": "gpt-4o-mini",
            "max_tokens": 220,  # JSON output is short; lower cap = faster response
            "temperature": 0.2,
            "response_format": {"type": "json_object"},
            "messages": [
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Identify what is shown in this image following your instructions.",
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{image_base64}",
                                "detail": "low",
                            },
                        },
                    ],
                },
            ],
        }

        openai_response = requests.post(
            OPENAI_ENDPOINT,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {OPENAI_API_KEY.value}",
            },
            json=openai_payload,
            timeout=20,
        )

        if openai_response.status_code != 200:
            print(f"OpenAI error {openai_response.status_code}: {openai_response.text}")
            return https_fn.Response(
                json.dumps({"error": "Recognition service error"}),
                status=502,
                content_type="application/json",
                headers=cors_headers,
            )

        content = openai_response.json()["choices"][0]["message"]["content"]
        result = json.loads(content)

        # Fill in sensible defaults in case the model omits a field
        result.setdefault("category", "unknown")
        result.setdefault("spoken_text", "I could not identify this clearly.")
        result.setdefault("detail", "")
        result.setdefault("confidence", 0)
        result.setdefault("needs_retake", False)
        result.setdefault("denomination", None)
        result.setdefault("denominations", [])
        result.setdefault("labels", [])

        return https_fn.Response(
            json.dumps(result),
            content_type="application/json",
            headers=cors_headers,
        )

    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": str(e)}),
            status=500,
            content_type="application/json",
            headers=cors_headers,
        )