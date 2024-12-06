import os
import json
import boto3
import base64
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    resp_data = {}

    if 'username' not in event or 'serverId' not in event:
        print("Incoming username or serverId missing - Unexpected")
        return resp_data

    input_username = event['username']
    input_serverId = event['serverId']
    print(f"Username: {input_username}, ServerId: {input_serverId}")

    if 'password' in event:
        input_password = event['password']
        if input_password == '' and (event['protocol'] == 'FTP' or event['protocol'] == 'FTPS'):
            print("Empty password not allowed")
            return resp_data
    else:
        print("No password, checking for SSH public key")
        input_password = ''

    # Lookup user's secret which can contain the password or SSH public keys
    resp = get_secret(f"aws/transfer/{input_serverId}/{input_username}")

    if resp is None:
        print("Secrets Manager exception thrown")
        return {}

    resp_dict = json.loads(resp)

    if input_password:
        if 'Password' not in resp_dict:
            print("Unable to authenticate user - No field match in Secret for password")
            return {}

        if resp_dict['Password'] != input_password:
            print("Unable to authenticate user - Incoming password does not match stored")
            return {}
    else:
        # SSH Public Key Auth Flow
        if 'PublicKey' not in resp_dict:
            print("Unable to authenticate user - No public keys found")
            return {}
        resp_data['PublicKeys'] = resp_dict['PublicKey'].split(",")

    # Set required fields
    resp_data['Role'] = resp_dict.get('Role', '')

    # Set optional fields
    if 'Policy' in resp_dict:
        resp_data['Policy'] = resp_dict['Policy']

    if 'HomeDirectoryDetails' in resp_dict:
        print("HomeDirectoryDetails found - Applying setting for virtual folders")
        resp_data['HomeDirectoryDetails'] = resp_dict['HomeDirectoryDetails']
        resp_data['HomeDirectoryType'] = "LOGICAL"
    elif 'HomeDirectory' in resp_dict:
        print("HomeDirectory found - Cannot be used with HomeDirectoryDetails")
        resp_data['HomeDirectory'] = resp_dict['HomeDirectory']
    else:
        print("HomeDirectory not found - Defaulting to /")

    print(f"Completed Response Data: {json.dumps(resp_data)}")
    return resp_data

def get_secret(secret_id):
    region = os.environ['SecretsManagerRegion']
    print(f"Secrets Manager Region: {region}")

    client = boto3.session.Session().client(service_name='secretsmanager', region_name=region)

    try:
        resp = client.get_secret_value(SecretId=secret_id)
        if 'SecretString' in resp:
            print("Found Secret String")
            return resp['SecretString']
        else:
            print("Found Binary Secret")
            return base64.b64decode(resp['SecretBinary'])
    except ClientError as err:
        print(f'Error Talking to SecretsManager: {err.response["Error"]["Code"]}, Message: {str(err)}')
        return None
        