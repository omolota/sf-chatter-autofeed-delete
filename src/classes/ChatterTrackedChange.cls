public class ChatterTrackedChange{
    public List<FeedEnabledObj> objList {get; set;}
    public List<FeedEnabledObj> objectsToDelete{get; set;}
    private Map<String, FeedEnabledObj> objListMap;
    private Map<String, FeedEnabledObj> objectsToDeleteMap;

    public List<FeedEnabledObj> deleteResultsOk{get; set;}
    public List<FeedEnabledObj> deleteResultsFail{get; set;}

    public String chosenObject{get; set;}
    public String message{get; set;}
    
    public ChatterTrackedChange(){
        objectsToDeleteMap = new Map<String, FeedEnabledObj>();
        objectsToDelete = objectsToDeleteMap.values();
        objListMap = new Map<String, FeedEnabledObj>();
        objList = objListMap.values();
        initObjList();
    }

    /** add the clicked object to the delete list */
    public PageReference addToObjectsToDelete(){
        transferFromObjectList();
        return null;
    }

    /** add the clicked object to the do not delete list */    
    public PageReference removeFromObjectsToDelete(){
        transferFromObjectToDelete();
        return null;
    }
    
    /** move the clicked object to delete list **/
    private void transferFromObjectList(){
        objectsToDeleteMap.put(chosenObject, objListMap.get(chosenObject));
        objectsToDelete = objectsToDeleteMap.values();
        objListMap.remove(chosenObject);
        objList = objListMap.values();
    }

    /** move the clicked object to UNdelete list **/
    private void transferFromObjectToDelete(){
        objListMap.put(chosenObject, objectsToDeleteMap.get(chosenObject));
        objList = objListMap.values();
        objectsToDeleteMap.remove(chosenObject);
        objectsToDelete = objectsToDeleteMap.values();
    }

    /** initialize object list **/
    private void initObjList(){
        objListMap = new Map<String, FeedEnabledObj>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 

        for (SObjectType s :  gd.values() ) {
            Schema.DescribeSObjectResult R = s.getDescribe();
            if(R.isFeedEnabled()){
                //init  FeedEnabledObj(String strName, String strTableName, boolean isCustomObject)
                objListMap.put(R.getName(), new FeedEnabledObj(R.getLabel(), R.getName(), R.isCustom()));
            }
        }
        objList = objListMap.values();   
    }
    
    /** transfer all objects to delete List **/
    private void transferAllToDeleteList(){
        objectsToDeleteMap.putAll(objListMap);
        objListMap = new Map<String, FeedEnabledObj>();
        objectsToDelete = objectsToDeleteMap.values();
        objList = objListMap.values();
    }

    /** transfer all objects to un-delete List **/
    private void transferAllToObjList(){
        objListMap.putAll(objectsToDeleteMap);
        objList = objListMap.values();    
        objectsToDeleteMap = new Map<String, FeedEnabledObj>();
        objectsToDelete = objectsToDeleteMap.values();
    }

    /** call this when delete ALL is clicked **/
    public PageReference deleteAllFeedTrack(){
        transferAllToDeleteList();
        return null;
    }

    /** call this when cancel ALL is clicked **/
    public PageReference cancelAllFeedTrack(){
        transferAllToObjList();    
        return null;
    }

    /** call this when Quick Delete All is clicked **/
    public PageReference quickDeleteAll(){
        message = '';
        if(deleteSpecialFeedTrack()){
            message = 'Special feed tracks deleted.';        
        }else{
            message = 'An error occured. \n' + message;
        }

        if(deleteTrackedChangeFromFeedItem()){
            message = message + '\nFeed track changes deleted.';        
        }else{
            message = 'An error occured. \n' + message;
        }

        return null;
    }

    /** call this when Quick Delete Special Events Track is clicked **/
    public PageReference quickDeleteSpecial(){
        message = '';
        if(deleteSpecialFeedTrack()){
            message = 'Special feed tracks deleted.';        
        }else{
            message = 'An error occured. \n' + message;
        }
        return null;
    }

    /** call this when Quick Delete Tracked Changes is clicked **/
    public PageReference quickDeleteTrackedChange(){
        message = '';
        if(deleteTrackedChangeFromFeedItem()){
            message = 'Feed track changes deleted.';        
        }else{
            message = 'An error occured. \n' + message;
        }
        return null;
    }
    
    /** delete chosen objects **/    
    public PageReference deleteFeedTrack(){
        deleteResultsOk = new List<FeedEnabledObj>();
        deleteResultsFail = new List<FeedEnabledObj>();

        //iterate each object and delete
        for(FeedEnabledObj feo : objectsToDelete){
            if(deleteFromObject(feo.tableName)){
                deleteResultsOk.add(feo);
            }else{
                deleteResultsFail.add(feo);            
            }
        }
        
        //move all objects back to un-delete list
        transferAllToObjList();
        return null;
    }

    /** delete trackfeed from sObjectName **/
    public boolean deleteFromObject(String sObjectName){
        String queryString = 'select id from ' + sObjectName +' where Type=\'TrackedChange\' and CommentCount=0 and LikeCount=0 limit 100';
        try{
            Database.delete(Database.query(queryString));
            return true;
        }catch(Exception e){
            return false;
        }
    }

    public boolean deleteSpecialFeedTrack(){
        String queryString = 'SELECT ID FROM FeedItem WHERE Type=\'BasicTemplateFeedItem\'';
        try{
            Database.delete(Database.query(queryString));
            return true;
        }catch(Exception e){
            message = String.valueOf(e);
            return false;
        }
    }

    public boolean deleteTrackedChangeFromFeedItem(){
        String queryString = 'SELECT ID FROM FeedItem WHERE Type=\'TrackedChange\'';
        try{
            Database.delete(Database.query(queryString));
            return true;
        }catch(Exception e){
            message = String.valueOf(e);
            return false;
        }
    }

    /** Model **/
    public class FeedEnabledObj{
        public String name {get; set;}
        public String objName {get; set;}
        public String tableName {get; set;}

        public FeedEnabledObj(){
        }
                
        public FeedEnabledObj(String strName, String strTableName, boolean isCustomObject){
            name = strName;
            objName = strTableName;
            if(isCustomObject)
                tableName = strTableName.subString(0, strTableName.length()-1)+'Feed';            
            else
                tableName = strTableName+'Feed';
        }
        
    }
    
    /** test method **/
    static testMethod void testThisClass(){
        ChatterTrackedChange ctc = new ChatterTrackedChange(); 
        if(ctc.objList.size()>0)
            ctc.chosenObject=ctc.objList.get(0).objName;
        System.assertEquals(ctc.chosenObject, ctc.objList.get(0).objName);

        //test method add objects to delete
        Integer nAllObjects = ctc.objList.size();
        ctc.addToObjectsToDelete();
        System.assertEquals(ctc.objectsToDelete.size(), 1);
        System.assertEquals(ctc.objectsToDelete.get(0).objName, ctc.chosenObject);
        System.assertEquals(ctc.objList.size(), --nAllObjects);
        
        //test method remove from objects to delete
        ctc.removeFromObjectsToDelete();
        System.assertEquals(ctc.objectsToDelete.size(), 0);
        System.assertEquals(ctc.objList.size(), ++nAllObjects);

        //test delete feed track
        ctc.addToObjectsToDelete();
        ctc.deleteFeedTrack();
        System.assertEquals(ctc.objectsToDelete.size(), 0);
        System.assertEquals(ctc.objList.size(), nAllObjects);

        //test delete ALL
        ctc.deleteAllFeedTrack();
        System.assertEquals(ctc.objectsToDelete.size(), nAllObjects);
        System.assertEquals(ctc.objList.size(), 0);
        ctc.deleteFeedTrack();
        System.assertEquals(ctc.objectsToDelete.size(), 0);
        System.assertEquals(ctc.objList.size(), nAllObjects);

        //test cancel ALL
        ctc.deleteAllFeedTrack();
        ctc.cancelAllFeedTrack();
        System.assertEquals(ctc.objectsToDelete.size(), 0);
        System.assertEquals(ctc.objList.size(), nAllObjects);
        
        //test quick links
        //Quick delete all
        ctc.quickDeleteAll();
        
        //Quick delete special events
        ctc.quickDeleteSpecial();
        
        //Quick delete tracked changes
        ctc.quickDeleteTrackedChange();

    }
    
 

}