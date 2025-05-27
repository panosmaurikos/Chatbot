import boto3
from botocore.exceptions import ClientError
import json
import uuid
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class MessageInput(BaseModel):
    message: str
    session_id: str | None = None

def send_message_to_agent(client, agent_id, agent_alias_id, session_id, message):
    try:
        response = client.invoke_agent(
            agentId=agent_id,
            agentAliasId=agent_alias_id,
            sessionId=session_id,
            inputText=message
        )
        response_text = ""
        for event in response.get("completion", []):
            if "chunk" in event and "bytes" in event["chunk"]:
                try:
                    chunk_data = event["chunk"]["bytes"].decode('utf-8')
                    if chunk_data:
                        chunk = json.loads(chunk_data) if chunk_data.startswith('{') else {"text": chunk_data}
                        if "text" in chunk:
                            response_text += chunk["text"]
                except json.JSONDecodeError:
                    response_text += chunk_data
        return response_text
    except ClientError as e:
        raise HTTPException(status_code=500, detail=f"Error calling Bedrock agent: {e.response['Error']['Message']}")

@app.post("/send-message")
async def invoke_bedrock_agent(input: MessageInput):
     # Replace with your actual AWS credentials and session token

    aws_access_key_id = "amazon_access_key_id"
    aws_secret_access_key = "amazon_secret_access_key"
    aws_session_token = ("amazon_session_token") 
    region_name = "us-west-2" # Change to your desired region

    client = boto3.client(
        "bedrock-agent-runtime",
        region_name=region_name,
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        aws_session_token=aws_session_token,
    )

    agent_id = "your_agent_id_here"  # Replace with your actual agent ID
    agent_alias_id = "your_agent_alias_id_here"  # Replace with your actual agent alias ID
    session_id = input.session_id if input.session_id else str(uuid.uuid4())

    response = send_message_to_agent(client, agent_id, agent_alias_id, session_id, input.message)
    if not response:
        raise HTTPException(status_code=500, detail="No response from agent")
    return {"response": response, "session_id": session_id}