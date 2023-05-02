using Amazon.CDK;
using Amazon.CDK.AWS.EC2;
using Constructs;

namespace SybaseToAuroraBlog
{
    public class NetworkResourcesStack : NestedStack
    {
        public Vpc Vpc { get; private set; }
        public SecurityGroup SecurityGroup { get; private set; }

        private readonly string _prefix;

        public NetworkResourcesStack(Construct scope, string id, NetworkStackProps props = null) : base(scope, id, props)
        {
            this._prefix = props?.Prefix ?? "NetworkStack";
            this.Vpc = CreateVpc();
            this.SecurityGroup = CreateSecurityGroup();
            ConfigureIngressRules(props?.IngressRules);
        }

        private Vpc CreateVpc()
        {
            return new Vpc(this, $"{_prefix}-vpc", new VpcProps
            {
                IpAddresses = IpAddresses.Cidr("10.0.0.0/16"),
                MaxAzs = 2,
                EnableDnsHostnames = true,
                EnableDnsSupport = true
            });
        }

        private SecurityGroup CreateSecurityGroup()
        {
            return new SecurityGroup(this, $"{_prefix}-sg", new SecurityGroupProps
            {
                Vpc = Vpc,
                SecurityGroupName = $"{_prefix}-sg"
            });
        }

        private void ConfigureIngressRules(IngressRule[] ingressRules)
        {
            if (ingressRules != null)
            {
                foreach (var rule in ingressRules)
                {
                    SecurityGroup.AddIngressRule(
                        Peer.Ipv4(rule.IpAddress),
                        Port.Tcp(rule.Port),
                        rule.Description
                    );
                }
            }
        }
    }

    public class NetworkStackProps : NestedStackProps
    {
        public string Prefix { get; set; }
        public IngressRule[] IngressRules { get; set; }
    }

    public class IngressRule
    {
        public string IpAddress { get; set; }
        public int Port { get; set; }
        public string Description { get; set; }
    }
}
