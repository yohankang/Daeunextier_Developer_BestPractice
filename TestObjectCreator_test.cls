/**
 * File Name    : TestObjectCreator_test.cls
 * Author       : yohan.kang
 * Date         : 2021-04-08
 * Tester       : TestObjectCreator_test_test.cls
 * Description  : 
 * Modification Log
 * ======================================================================================
 * Ver      Date        Author              Modification
 * ======================================================================================
 * 1.0      2021-04-08  yohan.kang          Create
 */
@IsTest
private class TestObjectCreator_test {
	static testMethod void doTest() {
        Account objAccount = TestObjectCreator.getObjAccount();
		insert objAccount;
		
		Opportunity objOpportunity = TestObjectCreator.getObjOpportunity();
		insert objOpportunity;
	}
}