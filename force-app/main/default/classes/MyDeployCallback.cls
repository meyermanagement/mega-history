/**
 * @description     call back class to implement Metadata.DeployCallBack
 * @author          Mark Meyer
 * @date            09/27/2024
 */
public class MyDeployCallback implements Metadata.DeployCallback {

    /**
     * @description inserts generic dummy record
     * @param result
     * @param context
     */
    public void handleResult(Metadata.DeployResult result,
                             Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug(result.success);
            // Deployment was successful
        } else {
            System.debug(result.errorMessage);
            // Deployment was not successful
        }
    }
}