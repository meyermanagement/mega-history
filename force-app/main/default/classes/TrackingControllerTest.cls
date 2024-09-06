@isTest
public class TrackingControllerTest {

    @isTest public static void testInit(){
        List<TrackingWrapper> wrappers = TrackingController.getRecords();
        wrappers = TrackingController.getObjects();
        TrackingWrapper wrapper = TrackingController.getObjectSelectedDetails('Account');
        wrapper = TrackingController.getObjectDetails(JSON.serialize(wrapper));
        List<String> fieldList = new List<String>();
        for(TrackingFieldDefinition tfd : wrapper.fieldList) fieldList.add(tfd.fieldAPIName);
        wrappers = TrackingController.submitMetaData(JSON.serialize(wrapper), JSON.serialize(wrappers), fieldList);
        List<MetadataWrapper> mdWrappers = TrackingController.generateMetadata(JSON.serialize(wrappers));
        String asyncId = TrackingController.handleCustomMetadata(JSON.serialize(mdWrappers));
        asyncId = TrackingController.deleteMetadata(mdWrappers);
        Map<String, String> fileMap = TrackingController.generateTriggerFiles(JSON.serialize(mdWrappers));
        asyncId = TrackingController.deployTriggers('', '');
        Boolean done = TrackingController.checkAsyncRequest(asyncId);
    }
}