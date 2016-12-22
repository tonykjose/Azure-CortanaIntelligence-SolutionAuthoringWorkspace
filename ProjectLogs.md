# Gain Access
* Request access to the *caqstelemetry* security group on [idweb](https://idweb). You can do this [here](https://idweb/identitymanagement/aspx/Groups/EditGroup.aspx?id=e3486844-76aa-4ed5-98fe-d6928b39904d&_p=1).
* Plug in the following connection information into your favorite tool that enables access to Kusto. Details on this follow in subsequent sections.
```
    Data Source: https://immlads.kusto.windows.net
    Client Security: Federated
    Connection String (Advanced): Data Source=https://immlads.kusto.windows.net:443;Initial Catalog=immlads;Federated Security=True
```
Once connected, you can work through your pattern logs to run ad-hoc queries and build dashboards/reports sourcing this data.

# Table Schema
Currently, we vend out a view 'ProjectLogs', on our cluster. Each record in this view represents a status change event for a step in a pattern. An example of this is the following: 

Timestamp | Project Name | Location | Pattern Id | Status | Step Id | Step Name | Step Type | Exception Trace | Project Id | Subscription Id | Inputs | Outputs
--------- | ------------ | -------- | ---------- | ------ | ------- | --------- | --------- | --------------- | ---------- | --------------- | ------ | -------
2016-12-20 18:15:55.455 | mstepsam | East US | multistep | Provisioning | 0000 | Create Storage Account | ArmDeployment |  | 942bdabf-9527-4518-8ca7-439e8b742a34 | d67f2755-21f7-4954-80bf-b446dcb8b4f6 | "[""baseUrl""]" | 
2016-12-20 18:22:39.163 | mstepsam | East US | multistep | Ready | 0000 | Create Storage Account | ArmDeployment |  | 942bdabf-9527-4518-8ca7-439e8b742a34 | d67f2755-21f7-4954-80bf-b446dcb8b4f6 | "[""baseUrl""]" | "[""stgAccountName"",""stgAccountKey"",""stgContainerName"",""stgBlobName"",""dataFactoryName"",""pipelineName"",""webJob1Name"",""webJob2Name"",""webJobSiteName""]"
2016-12-20 18:22:43.179 | mstepsam | East US | multistep | Provisioning | 0001 | Create Container and Blob in Storage Account | WebJob |  | 942bdabf-9527-4518-8ca7-439e8b742a34 | d67f2755-21f7-4954-80bf-b446dcb8b4f6 | "[""appName"",""jobName"",""arguments""]" | 
2016-12-20 18:27:25.535 | mstepsam | East US | multistep | Ready | 0001 | Create Container and Blob in Storage Account | WebJob |  | 942bdabf-9527-4518-8ca7-439e8b742a34 | d67f2755-21f7-4954-80bf-b446dcb8b4f6 | "[""appName"",""jobName"",""arguments""]" | 
2016-12-20 18:27:30.144 | mstepsam | East US | multistep | Provisioning | 0002 | Create Data Factory | ArmDeployment |  | 942bdabf-9527-4518-8ca7-439e8b742a34 | d67f2755-21f7-4954-80bf-b446dcb8b4f6 | "[""baseUrl"",""storageName"",""storageKey"",""storageContainerName"",""storageBlobName"",""pipelineName"",""dataFactoryName""]" | 
2016-12-20 18:37:16.578 | mstepsam | East US | multistep | Ready | 0002 | Create Data Factory | ArmDeployment |  | 942bdabf-9527-4518-8ca7-439e8b742a34 | d67f2755-21f7-4954-80bf-b446dcb8b4f6 | "[""baseUrl"",""storageName"",""storageKey"",""storageContainerName"",""storageBlobName"",""pipelineName"",""dataFactoryName""]" | "[""dataFactoryUrl""]"
2016-12-20 18:37:50.647 | mstepsam | East US | multistep | Provisioning | 0003 | Start Data Factory Pipeline | WebJob |  | 942bdabf-9527-4518-8ca7-439e8b742a34 | d67f2755-21f7-4954-80bf-b446dcb8b4f6 | "[""appName"",""jobName"",""requiresAuthorization""]" | 
2016-12-20 18:37:56.350 | mstepsam | East US | multistep | Ready | 0003 | Start Data Factory Pipeline | WebJob |  | 942bdabf-9527-4518-8ca7-439e8b742a34 | d67f2755-21f7-4954-80bf-b446dcb8b4f6 | "[""appName"",""jobName"",""requiresAuthorization""]" | 

Here, the workflow comprises of the following steps: 
* Create Storage Account
* Create Container and Blob in Storage Account	
* Create Data Factory
* Start Data Factory Pipeline

Each step progresses through various states as can be seen. A succesful workflow would have each step beginning with a *Provisioning* state to *Ready* state. The possible step states are the following: 

State | Description 
----- | -----------
Provisioning | Start status of a step. This indicates that execution has begun and is in progress.  
Ready |  Step succeeded. This is a terminal step status.
Error | Step failed due to a retriable error. The step will be retried at the next possible attempt. 
Timeout | Step failed on repeated retries leading to a retry timeout. This is a terminal step status.
Failed | Step failed on a non-retriable exception. This is a terminal step status. 

## Project Log Table Schema 
Below is the schema of the project logs view:

Field | Type | Description
----- | ---- | -----------
**ProjectId** | String | Auto-generated unique identifier for the deployed project. This is unique per deployment attempt.
**SubscriptionId** | String | Subscription Identifier used to deploy the pattern. 
**PatternId** | String | Unique identifier for the pattern being deployed.
**StepId** | String | Auto increment step number indicating the current step being processed.
**StepName** | String | Step name of current step passed in through Manifest. This corresponds to the **title* attribute for the provisioning step.
**StepType** | String | Step Type eg. ArmDeployment, Webjob etc.
**Location** | String | Location where the pattern is being deployed.
**Timestamp** | DateTime | Timestamp of the event.
**Status** | String | Status of the step execution. This can be one of [Provisioning, Ready, Error, Failed].
**Inputs** | String | Inputs passed in to step execution.
**Outputs** | String | Outputs returned from step execution.
**ExceptionTrace** | String | Exception trace from step if any.

# Querying Project Logs
### Retrieve all patterns with Failures
```
ProjectLogs 
| WHERE STATUS == 'Failed' 
| project PatternId
```

### Top Causes Of Failures 
```
ProjectLogs 
| WHERE STATUS == 'Failed' 
| summarize Failures=dcount(ProjectId) BY PatternId, ExceptionTrace 
| ORDER BY Failures ASC
```

### Failures Broken Down by Provisioning Step 
```
ProjectLogs 
| WHERE STATUS == 'Failed' 
| summarize Failures=dcount(ProjectId) BY PatternId, ExceptionTrace 
| ORDER BY Failures ASC
```

### Failures by Region
```
let pt = ProjectLogs 
| WHERE PatternId == 'predictivemaintenance';
pt 
| WHERE STATUS == 'Failed' 
| summarize FailedCount = dcount(ProjectId) BY Location
```

### Deployment Count By Region
```
let pt = ProjectLogs ;
pt 
| summarize TotalDeployments = dcount(ProjectId) BY Location
```

### Average Step Times
```
let x = ProjectLogs 
| summarize  StepTime = MAX(TIMESTAMP) - MIN(TIMESTAMP) BY StepName, ProjectId;
x 
| summarize AverageStepTime = avg(StepTime) BY StepName;
```

# Querying Tools
## Desktop Clients
### Kusto Explorer
This is a desktop application (much like SQL Server Management Studio) that lets you query against Kusto clusters/databases, by passing in a connection string.
#### Installation
* Download the installer [here]().
* The installer will prompt 
* Once the installer is complete, run the 'Kusto Explorer' application. 
* At the top left, click the "Connections" tab and select "Add connection" ![Add Connection Tab](/images/addconnections.png).

![Connection tab](/images/3.png)

* Set the connection string to the following for **Production**. 

![Connection String Production](/images/1.png)
* Set the connection string to the following for **Integration**. 

![Connection String Integration](/images/2.png)

* Once set, you will see a connection to our Kusto database under the connections pane on the left. Select **Immlads** connection and select **IMMLADS** database. 
* Once selected, you can now begin querying on the right-hand pane.

For further details, [refer here](https://kusto.azurewebsites.net/docs/tools/tools_kusto_explorer.html).

## Command Line
#### Installation
[Download the tool here.](aka.ms/kustools)

## Web UX
### Lens Explorer 
A web UX developed and maintained by the Geneva Analytics team. This can be used to query our Kusto databases. 
* Access it [here](aka.ms/lensv2).

#### Connecting to CAQS Database 
* Under the Data Source tab, select the ![Add Data Source](/images/addtab.png) button.

![Data Source Tab](/images/adddatasource.png)

* Set the *<CLUSTER>* field to **immlads** and hit "Add Datasource".

![Data Source Tab](/images/adddatasource2.png)

* Open a new tab to begin querying the tables. 

![Query Tab](/images/querytab.png)

[Detailed documentation available here.](https://microsoft.sharepoint.com/teams/WAG/EngSys/Monitor/AmdWiki/Lens%20V2%20User%20Guide.aspx)

### Kusto WebExplorer
This is the web counterpart of Kusto Explorer (windows client).
* Access it [here](https://immmlads.kusto.windows.net/IMMLADS?web=1).
* You can begin querying the tables with no prior connection set up.

Further details [available here](https://kusto.azurewebsites.net/docs/tools/tools_kusto_webexplorer.html).
