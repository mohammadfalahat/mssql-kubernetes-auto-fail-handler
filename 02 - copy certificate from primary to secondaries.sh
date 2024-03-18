# Copy the certificate from the AG primary

export NAMESPACE="-n appraisal"

# Retrieve the pod names to variables
export podagpm=$(kubectl get pods $NAMESPACE -l app=appraisal-instance1 -o custom-columns=:metadata.name)
export podags1=$(kubectl get pods $NAMESPACE -l app=appraisal-instance2 -o custom-columns=:metadata.name)
export podags2=$(kubectl get pods $NAMESPACE -l app=appraisal-instance3 -o custom-columns=:metadata.name)

# First copy to local
echo Copying AG certificates from $podagpm to localhost
kubectl cp $NAMESPACE $podagpm:/var/opt/mssql/ag_certificate.cert ag_certificate.cert
kubectl cp $NAMESPACE $podagpm:/var/opt/mssql/ag_certificate.key  ag_certificate.key

# Turn it around to copy to secondary1
echo Copying AG certificates from localhost to pod $podags1
kubectl cp $NAMESPACE ag_certificate.cert $podags1:/var/opt/mssql
kubectl cp $NAMESPACE ag_certificate.key  $podags1:/var/opt/mssql

# -- AG secondary2
# Next copy to secondary2
echo Copying AG certificates from localhost to pod $podags2
kubectl cp $NAMESPACE ag_certificate.cert $podags2:/var/opt/mssql
kubectl cp $NAMESPACE ag_certificate.key  $podags2:/var/opt/mssql







### IN POWERSHELL:

# Define the namespace
$NAMESPACE='appraisal'

# Retrieve the pod names
$podagpm = kubectl get pods -n ${NAMESPACE} -l app=appraisal-instance1 -o custom-columns=:metadata.name | Select-Object -Last 1
$podags1 = kubectl get pods -n ${NAMESPACE} -l app=appraisal-instance2 -o custom-columns=:metadata.name | Select-Object -Last 1
$podags2 = kubectl get pods -n ${NAMESPACE} -l app=appraisal-instance3 -o custom-columns=:metadata.name | Select-Object -Last 1

# Copy certificates from AG primary to localhost
Write-Host "Copying AG certificates from ${podagpm} to localhost"
kubectl cp ${NAMESPACE}/${podagpm}:/var/opt/mssql/ag_certificate.cert ag_certificate.cert
kubectl cp ${NAMESPACE}/${podagpm}:/var/opt/mssql/ag_certificate.key  ag_certificate.key

# Copy certificates from localhost to secondary1
Write-Host "Copying AG certificates from localhost to pod $podags1"
kubectl cp ag_certificate.cert ${NAMESPACE}/${podags1}:/var/opt/mssql
kubectl cp ag_certificate.key  ${NAMESPACE}/${podags1}:/var/opt/mssql

# Copy certificates from localhost to secondary2
Write-Host "Copying AG certificates from localhost to pod $podags2"
kubectl cp ag_certificate.cert ${NAMESPACE}/${podags2}:/var/opt/mssql
kubectl cp ag_certificate.key  ${NAMESPACE}/${podags2}:/var/opt/mssql