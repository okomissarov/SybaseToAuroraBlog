using Amazon.CDK;
using Amazon.CDK.AWS.DMS;
using Amazon.CDK.AWS.EC2;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.RDS;
using Amazon.CDK.AWS.SecretsManager;
using Constructs;
using System.Text.Json;
using System.Linq;
using static Amazon.CDK.AWS.DMS.CfnEndpoint;
using System.Collections.Generic;

namespace SybaseToAuroraBlog
{
    public class SybaseToAuroraBlogStack : Stack
    {
        private const string Prefix = "blog";
        private const string UserName = "sa";
        private const string MyIpAddress = "0.0.0.0/0";
        private const string PostgresInstanceParameterGroup = "default.aurora-postgresql14";
        private const string PostgresClusterParameterGroup = "custom-aurora-postgresql13-babelfish-compat-4";
        private Credentials auroraCredentials = null;

        internal SybaseToAuroraBlogStack(Construct scope, string id, IStackProps props = null) : base(scope, id, props)
        {
            var networkStack = createNetworkStack();
            var auroraCluster = createAuroraBabelPostgresCluster(networkStack);
            createDmsResources(networkStack, auroraCluster);
            
            networkStack.SecurityGroup.AddIngressRule(Peer.Ipv4(MyIpAddress), Port.Tcp(5000), "Allow connections to Sybase instance on EC2");
            networkStack.SecurityGroup.AddIngressRule(Peer.Ipv4(MyIpAddress), Port.Tcp(3389), "Allow RDP connections to sybase EC2");
        }

        DatabaseCluster createAuroraBabelPostgresCluster(NetworkResourcesStack networkStack)
        {
            var engine = DatabaseClusterEngine.AuroraPostgres(new AuroraPostgresClusterEngineProps
            {
                Version = AuroraPostgresEngineVersion.VER_14_6
            });
            auroraCredentials = Credentials.FromGeneratedSecret(UserName);
    
            var auroraCluster = new DatabaseCluster(this, $"{Prefix}-aurora", new DatabaseClusterProps
            {
                Engine = engine,
                InstanceProps = new Amazon.CDK.AWS.RDS.InstanceProps
                {
                    SecurityGroups = new ISecurityGroup[] { networkStack.SecurityGroup },
                    Vpc = networkStack.Vpc,
                    AllowMajorVersionUpgrade = true,
                    AutoMinorVersionUpgrade = true,
                    PubliclyAccessible = true,
                    EnablePerformanceInsights = false,
                    InstanceType = InstanceType.Of(InstanceClass.R5, InstanceSize.LARGE),
                    VpcSubnets = new SubnetSelection { SubnetType = SubnetType.PUBLIC },
                    ParameterGroup = ParameterGroup.FromParameterGroupName(this, "instanceParametersGroup", PostgresInstanceParameterGroup)
                },
                DefaultDatabaseName = $"{Prefix}database",
                Credentials = auroraCredentials,
                RemovalPolicy = RemovalPolicy.DESTROY,
                StorageEncrypted = true,
                MonitoringInterval = Duration.Seconds(60),
                CloudwatchLogsRetention = Amazon.CDK.AWS.Logs.RetentionDays.ONE_DAY,
                ClusterIdentifier = $"{Prefix}-aurora",
                ParameterGroup = ParameterGroup.FromParameterGroupName(this, "clusterParametersGroup", PostgresClusterParameterGroup),
            });
            auroraCluster.Connections.AllowFrom(Peer.Ipv4(MyIpAddress), Port.Tcp(1433),
                "Allow Aurora Postgres traffic");
            auroraCluster.Connections.AllowFrom(Peer.Ipv4(MyIpAddress), Port.Tcp(5432),
                "Allow MS SQL/Babelfish  traffic");
            return auroraCluster;
        }
        NetworkResourcesStack createNetworkStack()
        {
            var networkStack = new NetworkResourcesStack(this, $"{Prefix}NetworkStack", new NetworkStackProps
            {
                Prefix = Prefix,
                IngressRules = null
            });
            networkStack.SecurityGroup.AddIngressRule(
                         Peer.Ipv4(networkStack.Vpc.VpcCidrBlock),
                         Port.AllTraffic(),
                         "Allow all traffic WITHIN VPC"
                     );
            return networkStack;
        }

        void createDmsResources(NetworkResourcesStack networkResources, DatabaseCluster auroraCluster)
        {
            //this code creates secret for sybase in secret manager. do not pupulate actual values here. do it manually in SM
            var sybaseSecretTemplate = new{
                username = "fill in secrets manager",
                password = "fill in secrets manager",
                port = "5000",
                dbname = "fill in secrets manager",
                host = "pubs3",
                sslmode = "none"
            };
            var sybaseSecret = new Secret(this, "sybaseSecret", new SecretProps{
                GenerateSecretString = new SecretStringGenerator{
                        SecretStringTemplate = JsonSerializer.Serialize(sybaseSecretTemplate),
                        GenerateStringKey = "Password"
                        }
            });

            var babelfishSecret = new Secret(this, "babelfishSecret", new SecretProps{
               SecretObjectValue = new Dictionary<string, SecretValue>{
                {"password",  auroraCluster.Secret.SecretValueFromJson("password")},
                {"port", SecretValue.UnsafePlainText("1433")},
                {"host", auroraCluster.Secret.SecretValueFromJson("host")},
                {"username", auroraCluster.Secret.SecretValueFromJson("username")}
               }
            });

            var vpcRole = initializeDmsRole();
            sybaseSecret.GrantRead(vpcRole);
            auroraCluster.Secret.GrantRead(vpcRole);
            babelfishSecret.GrantRead(vpcRole);

            var subnetGroup = new CfnReplicationSubnetGroup(this, "dmsSubnetGroup", new CfnReplicationSubnetGroupProps
            {
                ReplicationSubnetGroupDescription = "Subnet group for dms",
                SubnetIds = networkResources.Vpc.PublicSubnets.Select(subnet => subnet.SubnetId).ToArray()
            });
            var dmsReplicationProps = initDmsConstructsProps(networkResources.Vpc, vpcRole, 
            networkResources.SecurityGroup, subnetGroup, sybaseSecret.SecretArn, babelfishSecret.SecretArn);
            var dmsResources = new DmsResourcesConstruct(this, "DMS Replication", dmsReplicationProps);

            // make CloudFormation wait for role and subnet group creation before it creates dms stack. by default it does not wait which leads to insufficient role/permission issues
            dmsResources.ReplicationInstance.Node.AddDependency(new IDependable[] { subnetGroup });
            subnetGroup.Node.AddDependency(new IDependable[] { vpcRole });

            //database secrets are stored in secrets manager. VPC endpoint is needed for DMS to access SM
            networkResources.Vpc.AddInterfaceEndpoint("dms-endpoint", new InterfaceVpcEndpointOptions
            {
                Service = InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
                SecurityGroups = new ISecurityGroup[] { networkResources.SecurityGroup }
            });
        }

        Role initializeDmsRole()
        {
        
            var role = new Role(this, "dms-vpc-role", new RoleProps
                {
                    AssumedBy = new ServicePrincipal($"dms.{this.Region}.amazonaws.com"),
                    RoleName = "dms-vpc-role",
                    Description = "DMS Role"
                });

                // Add required policies to the Role
                role.AddToPolicy(new PolicyStatement(new PolicyStatementProps
                {
                    Effect = Effect.ALLOW,
                    Resources = new [] { "*" },
                    Actions = new [] { "sts:AssumeRole" }
                }));

                role.AddToPolicy(new PolicyStatement(new PolicyStatementProps
                {
                    Effect = Effect.ALLOW,
                    Resources = new [] { "*" },
                    Actions = new []
                    {
                        "dms:*"
                    }
                }));

                role.AddToPolicy(new PolicyStatement(new PolicyStatementProps
                {
                    Effect = Effect.ALLOW,
                    Resources = new [] { "*" },
                    Actions = new []
                    {
                        "iam:GetRole",
                        "iam:PassRole",
                        "iam:CreateRole",
                        "iam:AttachRolePolicy"
                    }
                }));

                role.AddToPolicy(new PolicyStatement(new PolicyStatementProps
                {
                    Effect = Effect.ALLOW,
                    Resources = new [] { "*" },
                    Actions = new []
                    {
                        "ec2:CreateVpc",
                        "ec2:CreateSubnet",
                        "ec2:DescribeVpcs",
                        "ec2:DescribeInternetGateways",
                        "ec2:DescribeAvailabilityZones",
                        "ec2:DescribeSubnets",
                        "ec2:DescribeSecurityGroups",
                        "ec2:ModifyNetworkInterfaceAttribute",
                        "ec2:CreateNetworkInterface",
                        "ec2:DeleteNetworkInterface"
                    }
                }));

            role.AddToPolicy(
            new PolicyStatement(new PolicyStatementProps
            {
                Effect = Effect.ALLOW,
                Resources = new string[] { "*" },
                Actions = new string[]
                {
                        "kms:ListAliases",
                        "kms:DescribeKey",
                        "kms:Decrypt"
                        }
                }));

            role.AddToPolicy(new PolicyStatement(new PolicyStatementProps
            {
                Effect = Effect.ALLOW,
                Resources = new[] { "*" },
                    Actions = new []
                    {
                        "logs:DescribeLogGroups",
                        "logs:DescribeLogStreams",
                        "logs:FilterLogEvents",
                        "logs:GetLogEvents"
                    }
                }));

            var dmsVpcManagementRolePolicy = ManagedPolicy.FromManagedPolicyArn(
            this,
            "AmazonDMSVPCManagementRole",
            "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
            );
            role.AddManagedPolicy(dmsVpcManagementRolePolicy);

            return role;
        }

        DmsStackProps initDmsConstructsProps(Vpc vpc, Role vpcRole, SecurityGroup securityGroup, 
        CfnReplicationSubnetGroup subnetGroup, string sourceSecretArn, string targetSecretArn)
        {
            DmsStackProps dmsProps = new DmsStackProps();
            dmsProps.Prefix = Prefix;
            dmsProps.CfnReplicationInstanceProps = new CfnReplicationInstanceProps
            {
                ReplicationInstanceClass = "dms.r5.large",
                EngineVersion = "3.4.7",
                AutoMinorVersionUpgrade = true,
                PubliclyAccessible = true,
                AllocatedStorage = 40,
                MultiAz = false,
                ReplicationInstanceIdentifier = "replication-instance",
                ReplicationSubnetGroupIdentifier = subnetGroup.Ref,
                VpcSecurityGroupIds  = new string[] { securityGroup.SecurityGroupId }
            };
            dmsProps.SourceEndpointProps = new CfnEndpointProps
            {
                EndpointType = "source",
                EngineName = "sybase",
                DatabaseName = "pubs3",
                SybaseSettings = new SybaseSettingsProperty
                {
                    SecretsManagerSecretId = sourceSecretArn,
                    SecretsManagerAccessRoleArn = vpcRole.RoleArn
                }
            };
            dmsProps.TargetEndpointProps = new CfnEndpointProps
            {
                EndpointType = "target",
                EngineName = "babelfish",
                DatabaseName = "pubs3",
                MicrosoftSqlServerSettings = new MicrosoftSqlServerSettingsProperty
                {
                    SecretsManagerSecretId = targetSecretArn,
                    SecretsManagerAccessRoleArn = vpcRole.RoleArn,
                }
            };
            dmsProps.TableMappings =
            "{  \"rules\": [    {      \"rule-type\": \"selection\",      \"rule-id\": \"2\",      \"rule-name\": \"2\",      \"object-locator\": {        \"schema-name\": \"%\",        \"table-name\": \"%\"      },      \"rule-action\": \"include\",      \"filters\": []    }  ]}";
            return dmsProps;
        }
    }
}
