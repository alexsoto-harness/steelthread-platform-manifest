"""Steel Thread demo Lambda: hello world that returns the deployed candidate SHA."""
import json
import os


def handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({"hello": "steelthread", "candidate_sha": os.environ.get("CANDIDATE_SHA", "unknown")}),
    }
