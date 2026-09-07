import os
import sys
from time import strftime, sleep
import boto3
from botocore.exceptions import ClientError

AWS_DEFAULT_REGION = 'eu-central-1'
DEPLOYMENT_GROUP_NAME = 'DG1'
DEPLOYMENT_CONFIG = 'CodeDeployDefault.OneAtATime'

BUCKET_KEY = os.getenv('APPLICATION_NAME') + '/latest_bitbucket_builds.tar.gz'

def deploy_new_revision():
    """
    Deploy a new application revision to AWS CodeDeploy Deployment Group
    """
    try:
        client = boto3.client('codedeploy', region_name=AWS_DEFAULT_REGION)
    except ClientError as err:
        print("Failed to create boto3 client.\n" + str(err))
        return False

    try:
        response = client.create_deployment(
            applicationName=str(os.getenv('APPLICATION_NAME')),
            deploymentGroupName=DEPLOYMENT_GROUP_NAME,
            revision={
                'revisionType': 'S3',
                's3Location': {
                    'bucket': os.getenv('S3_BUCKET'),
                    'key': BUCKET_KEY,
                    'bundleType': 'tgz'
                }
            },
            deploymentConfigName=DEPLOYMENT_CONFIG,
            description='New PHP EC2 deployment',
            ignoreApplicationStopFailures=True
        )
    except ClientError as err:
        print("Failed to deploy application revision.\n" + str(err))
        return False     
           
    """
    Wait for deployment to complete
    """
    while 1:
        try:
            deploymentResponse = client.get_deployment(
                deploymentId=str(response['deploymentId'])
            )
            deploymentStatus = deploymentResponse['deploymentInfo']['status']
            if deploymentStatus == 'Succeeded':
                print("Deployment Succeeded")
                return True
            elif deploymentStatus in ['Failed', 'Stopped']:
                print("Deployment Failed")
                
                # Get deployment failure details
                deployment_info = deploymentResponse['deploymentInfo']
                deployment_id = response['deploymentId']
                
                # Print general error information if available
                if 'errorInformation' in deployment_info:
                    error_info = deployment_info['errorInformation']
                    print(f"\n=== CodeDeploy Deployment Failure Details ===")
                    if 'errorCode' in error_info:
                        print(f"Error Code: {error_info['errorCode']}")
                    if 'errorMessage' in error_info:
                        print(f"Error Message: {error_info['errorMessage']}")
                
                # Get instance deployment statuses
                try:
                    instances_response = client.list_deployment_instances(
                        deploymentId=deployment_id
                    )
                    
                    if 'instancesList' in instances_response and instances_response['instancesList']:
                        print(f"\n=== Instance Deployment Statuses ===")
                        for instance_id in instances_response['instancesList']:
                            try:
                                instance_info = client.get_deployment_instance(
                                    deploymentId=deployment_id,
                                    instanceId=instance_id
                                )
                                instance_status = instance_info['instanceSummary']
                                print(f"\nInstance ID: {instance_id}")
                                print(f"  Status: {instance_status.get('status', 'Unknown')}")
                                
                                if 'lifecycleEvents' in instance_status:
                                    for event in instance_status['lifecycleEvents']:
                                        event_status = event.get('status', 'Unknown')
                                        event_name = event.get('lifecycleEventName', 'Unknown')
                                        print(f"  Lifecycle Event: {event_name} - {event_status}")
                                        
                                        # Print diagnostics if available
                                        if 'diagnostics' in event:
                                            diagnostics = event['diagnostics']
                                            if 'errorCode' in diagnostics:
                                                print(f"    Error Code: {diagnostics['errorCode']}")
                                            if 'message' in diagnostics:
                                                print(f"    Message: {diagnostics['message']}")
                                            if 'logTail' in diagnostics:
                                                print(f"    Log Tail:\n{diagnostics['logTail']}")
                            except ClientError as instance_err:
                                print(f"  Failed to get details for instance {instance_id}: {str(instance_err)}")
                except ClientError as list_err:
                    print(f"\nFailed to list deployment instances: {str(list_err)}")
                
                print("\n=== End of Failure Details ===\n")
                return False
            elif deploymentStatus in ['InProgress', 'Queued', 'Created']:
                sleep(2)
                continue
        except ClientError as err:
            print("Failed to deploy application revision.\n" + str(err))
            return False      
    return True

def main():
    if not deploy_new_revision():
        sys.exit(1)

if __name__ == "__main__":
    main()