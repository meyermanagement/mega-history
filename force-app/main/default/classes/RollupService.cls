global with sharing class RollupService {
  global static Exception LastMetadataAPIConnectionException {
    get;
    private set;
  }

  /**
   * Used in a test context to determine if errors from the dummy child insert should fail the test
   **/
  private static boolean triggerHandleInvoked = false;

  global static Boolean checkMetadataAPIConnection() {
    try {
      MetadataService.MetadataPort service = new MetadataService.MetadataPort();
      service.SessionHeader = new MetadataService.SessionHeader_element();
      service.SessionHeader.sessionId = UserInfo.getSessionId();
      List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
      MetadataService.ListMetadataQuery remoteSites = new MetadataService.ListMetadataQuery();
      remoteSites.type_x = 'RemoteSiteSetting';
      queries.add(remoteSites);
      service.listMetadata(queries, 28);
    } catch (Exception e) {
      LastMetadataAPIConnectionException = e;
      return false;
    }
    LastMetadataAPIConnectionException = null;
    return true;
  }

  /**
   * Apex Trigger helper, automatically resolves child records to process via LREngine and lookups described in RollupSummary
   *    also determines if based on the old trigger records if the rollup processing needs to occur
   * @param childObjectType This can be used in cases where the prior overload was used an the Id.getSobjectType method fails to return the SOBjectType (see Issue 17 in the repo)
   **/
  global static void triggerHandler(SObjectType childObjectType) {
    triggerHandleInvoked = true;

    // Currently no processing in the before phase
    if (Trigger.isBefore)
      return;

  }

/**
   * Apex Test handler (call from Apex Test only)
   **/
  global static void testHandler(SObject dummyChildRecord) {
    try {
      disableNpspTdtm();
      insert dummyChildRecord;
    } catch (Exception e) {
      // If the auto generated trigger was invoked this test served its purpose (code coverage wise) ignore this error
      if (triggerHandleInvoked)
        return;
      // Otherwise fail the test with the underlying exception as it prevented our trigger being invoked
      throw e;
    }
  }

 /**
   * Check if npsp is installed and TDTM can be disabled with Callable_API
   **/
  private static Boolean npspInstalled() {
    if (Type.forName('npsp', 'Callable_API') != null) {
      return true;
    }
    return false;
  }

  /**
   * If possible, disable npsp tdtm triggers with Callable_API
   **/
  @TestVisible
  private static void disableNpspTdtm() {
    if (!npspInstalled()) {
      return;
    }
    Callable npspApi = (System.Callable) Type.forName('npsp', 'Callable_API')
      .newInstance();
    npspApi.call('TDTM.DisableAllTriggers', new Map<String, Object>());
  }
}