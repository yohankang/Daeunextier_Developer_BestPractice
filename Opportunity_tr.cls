/*
IsWon은 Owner와 Admin만 처리할 수 있다.


Opportunity가 IsWon이 되면 OpportunityLineItem의 fm_ProductGroup__c(Product2.ProductGroup__c)(Picklist)값이
Account의 ProductGroup__c (MultiPicklist) 값에 포함되어 있지 않으면 포함시켜업데이트한다.

*/
public with sharing class Opportunity_tr {
	List<Opportunity> listNew = Trigger.new;
	List<Opportunity> listOld = Trigger.old;
	Map<Id, Opportunity> mapNew = (Map<Id, Opportunity>)Trigger.newMap;
	Map<Id, Opportunity> mapOld = (Map<Id, Opportunity>)Trigger.oldMap;
	
	public void run() {
		if(Trigger.isBefore && Trigger.isInsert) beforeInsert();
		else if(Trigger.isBefore && Trigger.isUpdate) beforeUpdate();
		else if(Trigger.isBefore && Trigger.isDelete) beforeDelete();
		else if(Trigger.isAfter && Trigger.isInsert) afterInsert();
		else if(Trigger.isAfter && Trigger.isUpdate) afterUpdate();
		else if(Trigger.isAfter && Trigger.isDelete) afterDelete();
		else if(Trigger.isAfter && Trigger.isUndelete) afterUndelete();
	}
	
	private void beforeInsert() {
		doValidate();
	}
	private void beforeUpdate() {
		doValidate();
	}
	private void beforeDelete() {}
	private void afterInsert() {
		doUpdateAccount();
	}
	private void afterUpdate() {
		doUpdateAccount();
		
		
		if(!mapAccountForUpdate.values().isEmpty()) update mapAccountForUpdate.values();
	}
	private void afterDelete() {}
	private void afterUndelete() {}
	//-------------------------------------------------------------------------------------------------------------- 권한
	//Profile 이름으로 admin 권한 체크하는 것도 좋지만
	private Id idProfileAdmin = [SELECT Id FROM Profile WHERE Name='System Administrator'][0].Id;
	
	//해당 개체의 ModifyAll 권한을 체크하는 것이 유지보수 차원에서 더 좋아 보입니다.
	private Boolean isPermissionModifyAll;
	private Boolean getIsPermissionModifyAll() {
		isPermissionModifyAll = false;
		
		PermissionSet objPermissionSet = [SELECT Id FROM PermissionSet WHERE ProfileId=:UserInfo.getProfileId()];
		List<ObjectPermissions> listPermission = [SELECT Id, PermissionsModifyAllRecords FROM ObjectPermissions WHERE ParentId=:objPermissionSet.Id AND SobjectType='Opportunity'];
		for(ObjectPermissions obj:listPermission) {
			if(obj.PermissionsModifyAllRecords) isPermissionModifyAll = true;
		}
		return isPermissionModifyAll;
	}
	//--------------------------------------------------------------------------------------------------------------
	//after 이후에 업데이트할 개체 정의 (key로 id가 있어야 중복 에러가 발생하지 않음
	private Map<Id, Account> mapAccountForUpdate = new Map<Id, Account>();
	
	
	
	//--------------------------------------------------------------------------------------------------------------
	//trigger내에서 참조할 개체 정의들
	private List<OpportunityLineItem> listOpportunityLineItem;
	private Map<Id, List<OpportunityLineItem>> mapOpportunityLineItem;
	private Map<Id, Account> mapAccount;
	
	//get 으로 필요한 경우에만 query를 날려 처리를 함
	//대상건만 필터도 좋지만, 전체를 구성해놓고 사용하는 것은 퍼포먼스 차이가 거의 없음
	private List<OpportunityLineItem> getListOpportunityLineItem() {
		if(listOpportunityLineItem==null) {
			Set<Id> setIdTarget = new Set<Id>();
			if(listNew!=null) {
				for(Opportunity obj:listNew) setIdTarget.add(obj.Id);
			}
			if(listOld!=null) {
				for(Opportunity obj:listOld) setIdTarget.add(obj.Id);
			}
			listOpportunityLineItem = [
					SELECT Id, fm_ProductGroup__c, OpportunityId
				FROM OpportunityLineItem
				WHERE OpportunityId in :setIdTarget
			];
		}
		return listOpportunityLineItem;
	}
	private Map<Id, List<OpportunityLineItem>> getMapOpportunityLineItem() {
		if(mapOpportunityLineItem==null) {
			mapOpportunityLineItem = new Map<Id, List<OpportunityLineItem>>();
			for(OpportunityLineItem obj:getListOpportunityLineItem()) {
				List<OpportunityLineItem> listUnit = mapOpportunityLineItem.get(obj.OpportunityId);
				if(listUnit==null) {
					listUnit = new List<OpportunityLineItem>();
					mapOpportunityLineItem.put(obj.OpportunityId, listUnit);
				}
				listUnit.add(obj);
			}
		}
		return mapOpportunityLineItem;
	}
	private Map<Id, Account> getMapAccount() {
		if(mapAccount==null) {
			mapAccount = new Map<Id, Account>();
			Set<Id> setIdTarget = new Set<Id>();
			if(listNew!=null) {
				for(Opportunity obj:listNew) {
					if(obj.AccountId!=null) setIdTarget.add(obj.AccountId);
				}
			}
			if(listOld!=null) {
				for(Opportunity obj:listOld) {
					if(obj.AccountId!=null) setIdTarget.add(obj.AccountId);
				}
			}
			mapAccount.putAll([
					SELECT Id, ProductGroup__c FROM Account WHERE Id in:setIdTarget
			]);
		}
		return mapAccount;
	}
	
	
	
	//--------------------------------------------------------------------------------------------------------------
	private void doValidate() {
		for(Opportunity obj:listNew) {
			//insert , update를 같이 사용할때 조건를 무슨값일때 보다 무슨값으로 insert되거나 변경되었을때로 해야 함
			if(obj.IsWon && (mapOld==null || !mapOld.get(obj.Id).IsWon) && !UserInfo.getUserId().equals(obj.OwnerId) && getIsPermissionModifyAll()) {
				//메세지는 모두 Custom Label 처리
				obj.addError(Label.valid_CanWon);
			}
		}
	}
	
	private void doUpdateAccount() {
		for(Opportunity obj:listNew) {
			if(obj.IsWon && (mapOld==null || !mapOld.get(obj.Id).IsWon)) {
				Account objAccount = getMapAccount().get(obj.AccountId);
				List<OpportunityLineItem> listOpportunityLineItem = getMapOpportunityLineItem().get(obj.Id);
				List<String> listStrProductGroupValue = new List<String>();
				if(objAccount.ProductGroup__c!=null) listStrProductGroupValue = objAccount.ProductGroup__c.split(';');
				if(listOpportunityLineItem!=null) {
					for(OpportunityLineItem objItem:listOpportunityLineItem) {
						if(!listStrProductGroupValue.contains(objItem.fm_ProductGroup__c)) objAccount.ProductGroup__c = objAccount.ProductGroup__c + ';' + objItem.fm_ProductGroup__c;
					}
				}
				
				mapAccountForUpdate.put(objAccount.Id, objAccount);
			}
		}
	}
	
	//--------------------------------------------------------------------------------------------------------------
	@TestVisible private void testMe(Opportunity obj) {
		listNew = new List<Opportunity>();
		listNew.add(obj);
		mapNew = new Map<Id, Opportunity>();
		mapNew.put(obj.Id, obj);
		
		Opportunity objOld = obj.clone(false);
		
		listOld = new List<Opportunity>();
		listOld.add(objOld);
		mapOld = new Map<Id, Opportunity>();
		mapOld.put(obj.Id, objOld);
		
		//수식필드등이 있는 데이타등의 테스트를 위햇는 Json 방식으로 개체에 할당하여 테스트를 진행하면 편합니다.
		String strJsonOpportunityLineItemOpportunity = '{"Id":"TestId", "IsWon":true, "AccountId":"' + obj.AccountId + '"}';
		String strJsonOpportunityLineItemOpportunityOld = '{"Id":"TestId", "IsWon":false, "AccountId":"' + obj.AccountId + '"}';

		Opportunity obj2 = (Opportunity) JSON.deserialize(strJsonOpportunityLineItemOpportunity, Opportunity.class);
		Opportunity obj2Old = (Opportunity) JSON.deserialize(strJsonOpportunityLineItemOpportunityOld, Opportunity.class);
		
		listNew.add(obj2);
		mapNew.put(obj2.Id, obj2);
		listOld.add(obj2);
		mapOld.put(obj2Old.Id, obj2Old);
		
		String strJsonOpportunityLineItem = '{"OpportunityId":"TestId","fm_ProductGroup__c":"TV"}';
		OpportunityLineItem objItem = (OpportunityLineItem) JSON.deserialize(strJsonOpportunityLineItem, OpportunityLineItem.class);
		List<OpportunityLineItem> listItem = new List<OpportunityLineItem>();
		listItem.add(objItem);
		getMapOpportunityLineItem().put(obj2.Id, listItem);
		
		doUpdateAccount();
	}
}