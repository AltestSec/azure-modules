import azure.functions as func
import logging
import json
import requests
from datetime import datetime, timedelta
import pytz
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
import os

app = func.FunctionApp()

# Hungarian holidays for 2024-2025 (extend as needed)
HUNGARIAN_HOLIDAYS = [
    "2024-01-01",  # New Year's Day
    "2024-03-15",  # National Day
    "2024-03-29",  # Good Friday
    "2024-04-01",  # Easter Monday
    "2024-05-01",  # Labour Day
    "2024-05-20",  # Whit Monday
    "2024-08-20",  # St. Stephen's Day
    "2024-10-23",  # National Day
    "2024-11-01",  # All Saints' Day
    "2024-12-25",  # Christmas Day
    "2024-12-26",  # Boxing Day
    "2025-01-01",  # New Year's Day
    "2025-03-15",  # National Day
    "2025-04-18",  # Good Friday
    "2025-04-21",  # Easter Monday
    "2025-05-01",  # Labour Day
    "2025-06-09",  # Whit Monday
    "2025-08-20",  # St. Stephen's Day
    "2025-10-23",  # National Day
    "2025-11-01",  # All Saints' Day
    "2025-12-25",  # Christmas Day
    "2025-12-26",  # Boxing Day
]

@app.timer_trigger(schedule="0 0 * * * *", arg_name="myTimer", run_on_startup=False,
                   use_monitor=False) 
def vm_scheduler(myTimer: func.TimerRequest) -> None:
    """
    Azure Function that runs every hour to manage VM state based on:
    - Work hours (9 AM - 6 PM CET)
    - Weekends (Saturday, Sunday)
    - Hungarian holidays
    """
    
    if myTimer.past_due:
        logging.info('The timer is past due!')

    # Get current time in CET
    cet = pytz.timezone('Europe/Budapest')
    current_time = datetime.now(cet)
    current_hour = current_time.hour
    current_day = current_time.strftime('%A')
    current_date = current_time.strftime('%Y-%m-%d')
    
    logging.info(f'VM Scheduler triggered at {current_time}')
    
    # Determine if VMs should be running
    should_run_vms = should_vms_be_running(current_hour, current_day, current_date)
    
    # Get Azure credentials and subscription info
    subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
    resource_group = os.environ.get('RESOURCE_GROUP_NAME', 'rg-playground')
    pool_type = os.environ.get('POOL_TYPE', 'web')
    vm_count = int(os.environ.get('VM_COUNT', '2'))
    
    try:
        # Initialize Azure clients
        credential = DefaultAzureCredential()
        compute_client = ComputeManagementClient(credential, subscription_id)
        
        # Manage VMs based on schedule
        for i in range(1, vm_count + 1):
            vm_name = f"vm-{pool_type}-{i}"
            
            try:
                # Get current VM status
                vm_status = get_vm_status(compute_client, resource_group, vm_name)
                
                if should_run_vms and vm_status != 'VM running':
                    # Start VM
                    logging.info(f'Starting VM: {vm_name}')
                    start_vm(compute_client, resource_group, vm_name)
                    
                elif not should_run_vms and vm_status == 'VM running':
                    # Stop VM
                    logging.info(f'Stopping VM: {vm_name}')
                    stop_vm(compute_client, resource_group, vm_name)
                    
                else:
                    logging.info(f'VM {vm_name} is already in correct state: {vm_status}')
                    
            except Exception as e:
                logging.error(f'Error managing VM {vm_name}: {str(e)}')
                
    except Exception as e:
        logging.error(f'Error initializing Azure clients: {str(e)}')

def should_vms_be_running(hour: int, day: str, date: str) -> bool:
    """
    Determine if VMs should be running based on business rules
    """
    # Check if it's a weekend
    if day in ['Saturday', 'Sunday']:
        return False
    
    # Check if it's a Hungarian holiday
    if date in HUNGARIAN_HOLIDAYS:
        return False
    
    # Check if it's outside work hours (9 AM - 6 PM CET)
    if hour < 9 or hour >= 18:
        return False
    
    return True

def get_vm_status(compute_client: ComputeManagementClient, resource_group: str, vm_name: str) -> str:
    """
    Get the current status of a VM
    """
    try:
        vm_status = compute_client.virtual_machines.instance_view(resource_group, vm_name)
        for status in vm_status.statuses:
            if status.code.startswith('PowerState/'):
                return status.display_status
        return 'Unknown'
    except Exception as e:
        logging.error(f'Error getting VM status for {vm_name}: {str(e)}')
        return 'Unknown'

def start_vm(compute_client: ComputeManagementClient, resource_group: str, vm_name: str):
    """
    Start a VM
    """
    try:
        async_vm_start = compute_client.virtual_machines.begin_start(resource_group, vm_name)
        async_vm_start.wait()
        logging.info(f'Successfully started VM: {vm_name}')
    except Exception as e:
        logging.error(f'Error starting VM {vm_name}: {str(e)}')

def stop_vm(compute_client: ComputeManagementClient, resource_group: str, vm_name: str):
    """
    Stop (deallocate) a VM
    """
    try:
        async_vm_stop = compute_client.virtual_machines.begin_deallocate(resource_group, vm_name)
        async_vm_stop.wait()
        logging.info(f'Successfully stopped VM: {vm_name}')
    except Exception as e:
        logging.error(f'Error stopping VM {vm_name}: {str(e)}')

@app.function_name(name="GetHolidays")
@app.route(route="holidays", methods=["GET"])
def get_holidays(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP endpoint to get Hungarian holidays
    """
    try:
        year = req.params.get('year', str(datetime.now().year))
        
        # Filter holidays for the requested year
        year_holidays = [h for h in HUNGARIAN_HOLIDAYS if h.startswith(year)]
        
        return func.HttpResponse(
            json.dumps({
                "success": True,
                "data": {
                    "year": year,
                    "holidays": year_holidays
                }
            }),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f'Error getting holidays: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "success": False,
                "error": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )

@app.function_name(name="ManualVMControl")
@app.route(route="vm/{action}", methods=["POST"])
def manual_vm_control(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP endpoint for manual VM control
    """
    try:
        action = req.route_params.get('action')
        
        if action not in ['start', 'stop']:
            return func.HttpResponse(
                json.dumps({
                    "success": False,
                    "error": "Invalid action. Use 'start' or 'stop'"
                }),
                status_code=400,
                mimetype="application/json"
            )
        
        # Get request body
        req_body = req.get_json()
        vm_names = req_body.get('vm_names', [])
        
        if not vm_names:
            return func.HttpResponse(
                json.dumps({
                    "success": False,
                    "error": "vm_names array is required"
                }),
                status_code=400,
                mimetype="application/json"
            )
        
        # Get Azure credentials
        subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
        resource_group = os.environ.get('RESOURCE_GROUP_NAME', 'rg-playground')
        
        credential = DefaultAzureCredential()
        compute_client = ComputeManagementClient(credential, subscription_id)
        
        results = []
        for vm_name in vm_names:
            try:
                if action == 'start':
                    start_vm(compute_client, resource_group, vm_name)
                else:
                    stop_vm(compute_client, resource_group, vm_name)
                
                results.append({
                    "vm_name": vm_name,
                    "action": action,
                    "success": True
                })
            except Exception as e:
                results.append({
                    "vm_name": vm_name,
                    "action": action,
                    "success": False,
                    "error": str(e)
                })
        
        return func.HttpResponse(
            json.dumps({
                "success": True,
                "data": results
            }),
            status_code=200,
            mimetype="application/json"
        )
        
    except Exception as e:
        logging.error(f'Error in manual VM control: {str(e)}')
        return func.HttpResponse(
            json.dumps({
                "success": False,
                "error": str(e)
            }),
            status_code=500,
            mimetype="application/json"
        )