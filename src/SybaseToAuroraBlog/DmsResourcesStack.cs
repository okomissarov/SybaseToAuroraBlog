using Amazon.CDK;
using Constructs;
using Amazon.CDK.AWS.DMS;


namespace SybaseToAuroraBlog;

public class DmsResourcesConstruct : Construct
{
    public CfnReplicationInstance ReplicationInstance{get; private set;}
    public CfnEndpoint SourceEndpoint{get; private set;}
    public CfnEndpoint TargetEndpoint{get; private set;}
    public CfnReplicationTask ReplicationTask{get; private set;}


    public DmsResourcesConstruct(Construct scope, string id, DmsStackProps props) : base(scope, id)
    {
       var prefix = props?.Prefix ?? "DmsResourcesStack";

        this.ReplicationInstance = new CfnReplicationInstance(this, $"{prefix}-repl-instance", props.CfnReplicationInstanceProps);

        this.SourceEndpoint = new CfnEndpoint(this, $"{prefix}-source", props.SourceEndpointProps);

        this.TargetEndpoint = new CfnEndpoint(this, $"{prefix}-target", props.TargetEndpointProps);

        this.ReplicationTask = new CfnReplicationTask(this, $"{prefix}-migration-task", new CfnReplicationTaskProps
        {
            SourceEndpointArn = SourceEndpoint.Ref,
            TargetEndpointArn = TargetEndpoint.Ref,
            ReplicationInstanceArn = ReplicationInstance.Ref,
            MigrationType = "full-load",
            TableMappings = props.TableMappings,
            ReplicationTaskSettings = DmsStackProps.ReplicationTaskSettings
        });
    }
}

public class DmsStackProps
 {
    public CfnReplicationInstanceProps CfnReplicationInstanceProps  {get; set;}
    public CfnEndpointProps SourceEndpointProps {get; set;}
    public CfnEndpointProps TargetEndpointProps {get; set;}
    public string TableMappings  {get; set;}
    public string Prefix { get; set; }
    public const string ReplicationTaskSettings = @"{
        ""TargetMetadata"": {
        ""TargetSchema"": """",
        ""SupportLobs"": true,
        ""FullLobMode"": false,
        ""LobChunkSize"": 64,
        ""LimitedSizeLobMode"": true,
        ""LobMaxSize"": 32,
        ""InlineLobMaxSize"": 0,
        ""LoadMaxFileSize"": 0,
        ""ParallelLoadThreads"": 0,
        ""ParallelLoadBufferSize"": 0,
        ""BatchApplyEnabled"": false,
        ""TaskRecoveryTableEnabled"": false,
        ""ParallelLoadQueuesPerThread"": 0,
        ""ParallelApplyThreads"": 0,
        ""ParallelApplyBufferSize"": 0,
        ""ParallelApplyQueuesPerThread"": 0
    },
    ""FullLoadSettings"": {
        ""TargetTablePrepMode"": ""DO_NOTHING"",
        ""CreatePkAfterFullLoad"": false,
        ""StopTaskCachedChangesApplied"": false,
        ""StopTaskCachedChangesNotApplied"": false,
        ""MaxFullLoadSubTasks"": 2,
        ""TransactionConsistencyTimeout"": 600,
        ""CommitRate"": 10000
    },
    ""Logging"": {
        ""EnableLogging"": false,
        ""EnableLogContext"": false,
        ""LogComponents"": [
        {
            ""Id"": ""SOURCE_UNLOAD"",
            ""Severity"": ""LOGGER_SEVERITY_DEFAULT""
        },
        {
            ""Id"": ""SOURCE_CAPTURE"",
            ""Severity"": ""LOGGER_SEVERITY_DEFAULT""
        },
        {
            ""Id"": ""TARGET_LOAD"",
            ""Severity"": ""LOGGER_SEVERITY_DEFAULT""
        },
        {
            ""Id"": ""TARGET_APPLY"",
            ""Severity"": ""LOGGER_SEVERITY_DEFAULT""
        },
        {
            ""Id"": ""TASK_MANAGER"",
            ""Severity"": ""LOGGER_SEVERITY_DEFAULT""
        }
        ],
        ""CloudWatchLogGroup"": null,
        ""CloudWatchLogStream"": null
    },
    ""ControlTablesSettings"": {
        ""ControlSchema"": """",
        ""HistoryTimeslotInMinutes"": 5,
        ""HistoryTableEnabled"": false,
        ""SuspendedTablesTableEnabled"": false,
        ""StatusTableEnabled"": false
    },
    ""StreamBufferSettings"": {
        ""StreamBufferCount"": 3,
        ""StreamBufferSizeInMB"": 8,
        ""CtrlStreamBufferSizeInMB"": 5
    },
    ""ChangeProcessingDdlHandlingPolicy"": {
        ""HandleSourceTableDropped"": true,
        ""HandleSourceTableTruncated"": true,
        ""HandleSourceTableAltered"": true
    },
    ""ErrorBehavior"": {
        ""DataErrorPolicy"": ""LOG_ERROR"",
        ""DataTruncationErrorPolicy"": ""LOG_ERROR"",
        ""DataErrorEscalationPolicy"": ""SUSPEND_TABLE"",
        ""DataErrorEscalationCount"": 0,
        ""TableErrorPolicy"": ""SUSPEND_TABLE"",
        ""TableErrorEscalationPolicy"": ""STOP_TASK"",
        ""TableErrorEscalationCount"": 0,
        ""RecoverableErrorCount"": -1,
        ""RecoverableErrorInterval"": 5,
        ""RecoverableErrorThrottling"": true,
        ""RecoverableErrorThrottlingMax"": 1800,
        ""RecoverableErrorStopRetryAfterThrottlingMax"": false,
        ""ApplyErrorDeletePolicy"": ""IGNORE_RECORD"",
        ""ApplyErrorInsertPolicy"": ""LOG_ERROR"",
        ""ApplyErrorUpdatePolicy"": ""LOG_ERROR"",
        ""ApplyErrorEscalationPolicy"": ""LOG_ERROR"",
        ""ApplyErrorEscalationCount"": 0,
        ""ApplyErrorFailOnTruncationDdl"": false,
        ""FullLoadIgnoreConflicts"": true,
        ""FailOnTransactionConsistencyBreached"": false,
        ""FailOnNoTablesCaptured"": false
    },
    ""ChangeProcessingTuning"": {
        ""BatchApplyPreserveTransaction"": true,
        ""BatchApplyTimeoutMin"": 1,
        ""BatchApplyTimeoutMax"": 30,
        ""BatchApplyMemoryLimit"": 500,
        ""BatchSplitSize"": 0,
        ""MinTransactionSize"": 1000,
        ""CommitTimeout"": 1,
        ""MemoryLimitTotal"": 1024,
        ""MemoryKeepTime"": 60,
        ""StatementCacheSize"": 50
    },
    ""ValidationSettings"": {
        ""EnableValidation"": false,
        ""ValidationMode"": ""ROW_LEVEL"",
        ""ThreadCount"": 5,
        ""FailureMaxCount"": 10000,
        ""TableFailureMaxCount"": 1000,
        ""HandleCollationDiff"": false,
        ""ValidationOnly"": false,
        ""RecordFailureDelayLimitInMinutes"": 0,
        ""SkipLobColumns"": false,
        ""ValidationPartialLobSize"": 0,
        ""ValidationQueryCdcDelaySeconds"": 0,
        ""PartitionSize"": 10000
    },
    ""PostProcessingRules"": null,
    ""CharacterSetSettings"": null,
    ""LoopbackPreventionSettings"": null,
    ""BeforeImageSettings"": null
    }";

}
