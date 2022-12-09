/**
 * File Name    : TestObjectCreator.cls
 * Author       : yohan.kang
 * Date         : 2021-04-08
 * Tester       : TestObjectCreator_test.cls
 * Description  : 
 * Modification Log
 * ======================================================================================
 * Ver      Date        Author              Modification
 * ======================================================================================
 * 1.0      2021-04-08  yohan.kang          Create
 */
public with sharing class TestObjectCreator {
	private static Account objAccount;
	private static Opportunity objOpportunity;
	private static OpportunityLineItem objOpportunityLineItem;
	
	@TestVisible
	private static Account getObjAccount() {
		if(objAccount==null) {
			objAccount = new Account();
			objAccount.Name = '테스트 Account';
			objAccount.Grade__c = 'E';
			objAccount.Active__c = 'Yes';
		}
		return objAccount;
	}
	
	@TestVisible
	private static Opportunity getObjOpportunity() {
		if(objOpportunity==null) {
			objOpportunity = new Opportunity();
			objOpportunity.Name = '테스트 Opportunity';
			objOpportunity.StageName = getPickListValuesIntoList()[0];
			objOpportunity.CloseDate = system.today();
		}
		return objOpportunity;
	}

	
	private static List<String> getPickListValuesIntoList(){
		List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getValue());
		}
		return pickListValuesList;
	}
}