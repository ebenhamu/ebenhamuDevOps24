# Example how to use output of terfrom to extract public ip 
JENKINS_IP=$(terraform output -raw Monithor_jenkins_public_ip)
echo "Jenkins is running at $JENKINS_IP"
