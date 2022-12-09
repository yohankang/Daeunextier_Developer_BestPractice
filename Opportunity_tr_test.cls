@IsTest
private class Opportunity_tr_test {
	static testMethod void doTest() {
		//테스트클래스에서 개체를 정의할때에는 한 Class내에서만 처리하는 것이 좋습니다.
		Account objAccount = TestObjectCreator.getObjAccount();
		insert objAccount;
		
		Opportunity obj = TestObjectCreator.getObjOpportunity();
		obj.AccountId = objAccount.Id;
		
		Test.startTest();
		
		insert obj;
		update obj;
		
		new Opportunity_tr().testMe(obj);
		
		delete obj;
		undelete obj;
		
		Test.stopTest();
	}
}