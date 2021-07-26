/*
    Copyright (c) 2021 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2021
* @description Gift Selector Class in NPSP.
*/

public with sharing class GiftSelector {

    private List<String> additionalGiftsFieldsToQuery;

    public GiftSelector(GiftTemplate giftTemplate) {
        this.additionalGiftsFieldsToQuery = giftTemplate.giftFieldApiNames();
    }

    public List<DataImport__c> getGiftsFor(GiftBatchId giftBatchId) {
        String dataImportBatchLookup = String.valueOf(DataImport__c.NPSP_Data_Import_Batch__c);
        Id dataImportBatchId = giftBatchId.value();
        String queryString = new UTIL_Query()
            .withFrom(DataImport__c.SObjectType)
            .withSelectFields(fields())
            .withWhere(dataImportBatchLookup + ' =: dataImportBatchId')
            .withSecurityEnforced()
            .build();

        return Database.query(queryString);
    }

    public DataImport__c getGiftById(Id giftId, GiftTemplate formTemplate) {
        this.additionalGiftsFieldsToQuery = formTemplate.giftFieldApiNames();
        String queryString = new UTIL_Query()
            .withFrom(DataImport__c.SObjectType)
            .withSelectFields(fields())
            .withWhere('Id =: giftId')
            .withSecurityEnforced()
            .build();

        return Database.query(queryString);
    }

    public DataImport__c getGiftById(Id giftId, List<String> fieldsToQuery) {
        String queryString = new UTIL_Query()
            .withFrom(DataImport__c.SObjectType)
            .withSelectFields(fieldsToQuery)
            .withWhere('Id =: giftId')
            .withSecurityEnforced()
            .build();

        return Database.query(queryString);
    }

    private List<String> elevateFields() {
        List<String> elevateFieldApiNames = new List<String>{
            String.valueOf(DataImport__c.Elevate_Payment_Status__c),
            String.valueOf(DataImport__c.Payment_Declined_Reason__c),
            String.valueOf(DataImport__c.Payment_Elevate_Batch_ID__c)
        };

        return elevateFieldApiNames;
    }

    private List<String> coreFields() {
        List<String> giftEntryFieldApiNames = new List<String> {
            String.valueOf(DataImport__c.Account1Imported__c),
            String.valueOf(DataImport__c.Additional_Object_JSON__c),
            String.valueOf(DataImport__c.Contact1Imported__c),
            String.valueOf(DataImport__c.DonationImportStatus__c),
            String.valueOf(DataImport__c.DonationImported__c),
            String.valueOf(DataImport__c.Donation_Donor__c),
            String.valueOf(DataImport__c.FailureInformation__c),
            String.valueOf(DataImport__c.Id),
            String.valueOf(DataImport__c.NPSP_Data_Import_Batch__c),
            String.valueOf(DataImport__c.PaymentImportStatus__c),
            String.valueOf(DataImport__c.PaymentImported__c),
            String.valueOf(DataImport__c.Payment_Status__c),
            String.valueOf(DataImport__c.Status__c)
        };

        return giftEntryFieldApiNames;
    }

    private List<String> fields() {
        Set<String> queryFieldAsSet = new Set<String>();
        queryFieldAsSet.addAll(coreFields());
        if (this.additionalGiftsFieldsToQuery != null) {
            queryFieldAsSet.addAll(this.additionalGiftsFieldsToQuery);
        }
        if (GE_PaymentServices.getInstance().isElevateCustomer()) {
            queryFieldAsSet.addAll(elevateFields());
        }

        List<String> fields = new List<String>();
        fields.addAll(filterByReadAccess(queryFieldAsSet));

        return fields;
    }

    private List<String> filterByReadAccess(Set<String> fieldsToValidate) {
        List<String> hasReadAccessTo = new List<String>();
        for (String fieldApiName : fieldsToValidate) {
            DescribeFieldResult fieldDescribe =
                Schema.SObjectType.DataImport__c.fields.getMap().get(fieldApiName).getDescribe();

            If (fieldDescribe.isAccessible()) {
                hasReadAccessTo.add(fieldApiName);
            }
        }

        return hasReadAccessTo;
    }
}