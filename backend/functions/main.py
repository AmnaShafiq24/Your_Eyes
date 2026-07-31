from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app
from google.cloud import vision
import base64
import json
import re

set_global_options(max_instances=10)
initialize_app()

VALID_DENOMINATIONS = ["10", "20", "50", "100", "500", "1000", "5000"]

@https_fn.on_request()
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

        if not image_base64:
            return https_fn.Response(
                json.dumps({"error": "No image provided"}),
                status=400,
                content_type="application/json",
                headers=cors_headers,
            )

        image_bytes = base64.b64decode(image_base64)
        client = vision.ImageAnnotatorClient()
        image = vision.Image(content=image_bytes)

        # Label detection: what's in the image generally
        label_response = client.label_detection(image=image)
        labels = [label.description for label in label_response.label_annotations]

        # Text detection: read any numerals printed (for currency denomination)
        text_response = client.text_detection(image=image)
        detected_text = (
            text_response.text_annotations[0].description
            if text_response.text_annotations
            else ""
        )

        # Log the raw OCR text so we can see exactly what Vision API read
        print(f"OCR detected text: {detected_text!r}")

        # Extract any recognized denomination from the OCR text.
        # Strip commas so numbers like "1,000" are read as "1000".
        cleaned_text = detected_text.replace(",", "")
        numbers_found = re.findall(r"\d+", cleaned_text)
        print(f"Numbers found in OCR text: {numbers_found}")

        found_denomination = None
        for num in numbers_found:
            if num in VALID_DENOMINATIONS:
                found_denomination = num
                break

        return https_fn.Response(
            json.dumps({
                "labels": labels,
                "detectedText": detected_text,
                "numbersFound": numbers_found,
                "denomination": found_denomination,
            }),
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