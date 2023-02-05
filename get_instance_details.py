import json
from google.oauth2 import service_account
from googleapiclient import discovery

# SA json file.
KEY_FILE_LOCATION = '/path/to/service_account.json'

# GCP cloud authentication.
credentials = service_account.Credentials.from_json_keyfile_name(
    KEY_FILE_LOCATION,
    scopes=['https://www.googleapis.com/auth/cloud-platform']
)

# GCP client to auth the GCP cloud
compute = discovery.build('compute', 'v1', credentials=credentials)

# Instance Details
instance_name = 'instance_name'

# Get Instance details
result = compute.instances().get(
    project='my-gcp-project',
    zone='us-central1-a',
    instance=instance_name
).execute()

print(json.dumps(result))
