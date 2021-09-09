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
public with sharing class RD2_ChangeHistory {

    private RecurringDonationChangeHistory__c record;

    public RD2_ChangeHistory(RecurringDonationChangeHistory__c record) {
        this.record = record;
    }

    public RD2_ChangeView getChangeView() {
        RD2_ChangeView view = new RD2_ChangeView();
        view.changeType = this.record.ChangeType__c;
        view.id = this.record.Id;

        if (this.record.NewStatusReason__c != null) {
            view.statusReason = this.record.NewStatusReason__c;
        }

        view.changeDate = this.record.EffectiveDate__c;
        view.fields = buildFieldChangeViews();

        return view;
    }

    private RD2_FieldChangeView getCampaignChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newId = this.record.NewCampaign__c;
        view.oldId = this.record.PreviousCampaign__c;
        view.newValue = this.record.NewCampaign__r.Name;
        view.oldValue = this.record.PreviousCampaign__r.Name;

        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.LOOKUP);
        return view;
    }

    private RD2_FieldChangeView getAmountChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.oldValue = this.record.PreviousAmount__c;
        if (this.isAmountChanged()) {
            view.newValue = this.record.NewAmount__c;
        }
        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.npe03__Amount__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.MONEY);
        if (UserInfo.isMultiCurrencyOrganization()) {
            view.currencyCode = (String)this.record.get('CurrencyIsoCode');
        }
        return view;
    }

    private RD2_FieldChangeView getAnnualValueChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.oldValue = this.record.PreviousAnnualValue__c;
        if (this.isAnnualValueChanged()) {
            view.newValue = this.record.NewAnnualValue__c;
        }
        view.label = Label.RDCH_Annual_Value;
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.MONEY);
        if (UserInfo.isMultiCurrencyOrganization()) {
            view.currencyCode = (String)this.record.get('CurrencyIsoCode');
        }
        return view;
    }

    private RD2_FieldChangeView getStatusChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewStatus__c;
        view.oldValue = this.record.PreviousStatus__c;
        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.Status__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.TEXT);
        return view;
    }

    private RD2_FieldChangeView getFrequencyChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewInstallmentFrequency__c;
        view.oldValue = this.record.PreviousInstallmentFrequency__c;
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.NUMERIC);
        view.label = Label.RDCH_Frequency;

        return view;
    }

    private RD2_FieldChangeView getPeriodChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewInstallmentPeriod__c;
        view.oldValue = this.record.PreviousInstallmentPeriod__c;
        view.label = Label.pmtWizardIntervalPeriod;
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.TEXT);
        return view;
    }

    private RD2_FieldChangeView getPaymentMethodChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewPaymentMethod__c;

        if (this.record.NewPaymentMethod__c != null) {
            view.newValue = this.record.NewPaymentMethod__c;
        } else {
            view.newValue = Label.stgLabelFieldValueNone;
        }

        if (this.record.PreviousPaymentMethod__c != null) {
            view.oldValue = this.record.PreviousPaymentMethod__c;
        } else {
            view.oldValue = Label.stgLabelFieldValueNone;
        }

        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.PaymentMethod__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.TEXT);
        return view;
    }

    private List<RD2_FieldChangeView> buildFieldChangeViews() {
        List<RD2_FieldChangeView> fieldChanges = new List<RD2_FieldChangeView>();

        if (hasAmountPermissions()) {
            fieldChanges.add(getAmountChange());
        }

        if (hasAnnualValuePermissions()) {
            fieldChanges.add(getAnnualValueChange());
        }

        if (isCampaignChanged() && hasCampaignPermissions()) {
            fieldChanges.add(getCampaignChange());
        }

        if (isStatusChanged() && hasStatusPermissions()) {
            fieldChanges.add(getStatusChange());
        }

        if (isFrequencyChanged() && hasFrequencyPermissions()) {
            fieldChanges.add(getFrequencyChange());
        }

        if (isPeriodChanged() && hasPeriodPermissions()) {
            fieldChanges.add(getPeriodChange());
        }

        if (isPaymentMethodChanged() && hasPaymentPermissions()) {
            fieldChanges.add(getPaymentMethodChange());
        }

        return fieldChanges;
    }

    private Boolean hasAnnualValuePermissions() {
        return canReadRDCHFields(RecurringDonationChangeHistory__c.NewAnnualValue__c,
                RecurringDonationChangeHistory__c.PreviousAnnualValue__c);
    }

    private Boolean hasAmountPermissions() {
        return canReadRDCHFields(RecurringDonationChangeHistory__c.PreviousAmount__c,
                RecurringDonationChangeHistory__c.NewAmount__c);
    }

    private Boolean hasPaymentPermissions() {
        return canReadRDCHFields(RecurringDonationChangeHistory__c.PreviousPaymentMethod__c,
                RecurringDonationChangeHistory__c.NewPaymentMethod__c);
    }

    private Boolean hasPeriodPermissions() {
        return canReadRDCHFields(RecurringDonationChangeHistory__c.PreviousInstallmentPeriod__c,
                RecurringDonationChangeHistory__c.NewInstallmentPeriod__c);
    }

    private Boolean hasFrequencyPermissions() {
        return canReadRDCHFields(RecurringDonationChangeHistory__c.PreviousInstallmentFrequency__c,
                RecurringDonationChangeHistory__c.NewInstallmentFrequency__c);
    }

    private Boolean hasStatusPermissions() {
        return canReadRDCHFields(RecurringDonationChangeHistory__c.PreviousStatus__c,
                RecurringDonationChangeHistory__c.NewStatus__c);
    }

    private Boolean hasCampaignPermissions() {
        return canReadRDCHFields(RecurringDonationChangeHistory__c.PreviousCampaign__c,
                RecurringDonationChangeHistory__c.NewCampaign__c);
    }

    private Boolean canReadRDCHFields(Schema.SObjectField newField, Schema.SObjectField oldField) {
        String rdChangeHistorySObject = String.valueOf(RecurringDonationChangeHistory__c.SObjectType);
        return UTIL_Permissions.canRead(rdChangeHistorySObject, String.valueOf(newField))
                && UTIL_Permissions.canRead(rdChangeHistorySObject, String.valueOf(oldField));
    }

    private Boolean isAmountChanged() {
        return this.record.NewAmount__c != this.record.PreviousAmount__c;
    }

    private Boolean isAnnualValueChanged() {
        return this.record.PreviousAnnualValue__c != this.record.NewAnnualValue__c;
    }

    private Boolean isFrequencyChanged() {
        return this.record.PreviousInstallmentFrequency__c != this.record.NewInstallmentFrequency__c;
    }

    private Boolean isPeriodChanged() {
        return this.record.PreviousInstallmentPeriod__c != this.record.NewInstallmentPeriod__c;
    }

    private Boolean isStatusChanged() {
        return this.record.PreviousStatus__c != this.record.NewStatus__c;
    }

    private Boolean isCampaignChanged() {
        return this.record.NewCampaign__c != this.record.PreviousCampaign__c;
    }

    private Boolean isPaymentMethodChanged() {
        return this.record.NewPaymentMethod__c != this.record.PreviousPaymentMethod__c;
    }
}