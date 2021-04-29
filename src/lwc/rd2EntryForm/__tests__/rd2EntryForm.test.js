import {createElement} from 'lwc';
import Rd2EntryForm from 'c/rd2EntryForm';
import getRecurringSettings from '@salesforce/apex/RD2_EntryFormController.getRecurringSettings';
import hasRequiredFieldPermissions from '@salesforce/apex/RD2_EntryFormController.hasRequiredFieldPermissions';
import RD2_EntryFormMissingPermissions from '@salesforce/label/c.RD2_EntryFormMissingPermissions';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import {getObjectInfo, getPicklistValues} from 'lightning/uiObjectInfoApi';
import {getRecord} from 'lightning/uiRecordApi';
import {mockGetIframeReply} from "c/psElevateTokenHandler";

const recurringSettingsResponse = require('./data/getRecurringSettings.json');
const recurringDonationObjectInfo = require('./data/recurringDonationObjectInfo.json');
const installmentPeriodPicklistValues = require('./data/installmentPeriodPicklistValues.json');
const dayOfMonthPicklistValues = require('./data/dayOfMonthPicklistValues.json');
const contactPartialDescribe = require('./data/contactPartialDescribe.json');
const accountPartialDescribe = require('./data/accountPartialDescribe.json');
const contactGetRecord = require('./data/contactGetRecord.json');
const accountGetRecord = require('./data/accountGetRecord.json');

const mockScrollIntoView = jest.fn();

jest.mock('@salesforce/apex/RD2_EntryFormController.getRecurringSettings',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/RD2_EntryFormController.hasRequiredFieldPermissions',
    () => {
        return { default: jest.fn() }
    },
    { virtual: true }
);


describe('c-rd2-entry-form', () => {

    beforeEach(() => {
        getRecurringSettings.mockResolvedValue(recurringSettingsResponse);
        hasRequiredFieldPermissions.mockResolvedValue(true);
        window.HTMLElement.prototype.scrollIntoView = mockScrollIntoView;
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    })

    it('displays an error when user does not have required permissions', async () => {
        hasRequiredFieldPermissions.mockResolvedValue(false);
        const element = createRd2EntryForm();

        await flushPromises();

        expect(mockScrollIntoView).toHaveBeenCalledTimes(1);

        const saveButton = selectSaveButton(element);
        expect(saveButton.disabled).toBe(true);

        const formattedText = element.shadowRoot.querySelector('lightning-formatted-text');
        expect(formattedText.value).toBe(RD2_EntryFormMissingPermissions);
    });

    it('elevate customer selects Credit Card payment method then widget displayed', async () => {
        const element = createRd2EntryForm();
        const controller = new RD2FormController(element)

        await flushPromises();

        await setupWireMocksForElevate();
        controller.setDefaultInputFieldValues();

        controller.paymentMethod().changeValue('Credit Card');

        await flushPromises();

        const elevateWidget = controller.elevateWidget();
        expect(elevateWidget).toBeTruthy();

    });

    it('elevate customer selects ACH payment method then widget displayed', async () => {
        const element = createRd2EntryForm();
        const controller = new RD2FormController(element);
        await flushPromises();

        await setupWireMocksForElevate();
        controller.setDefaultInputFieldValues();

        controller.paymentMethod().changeValue('ACH');

        await flushPromises();

        const elevateWidget = controller.elevateWidget();
        expect(elevateWidget).toBeTruthy();
    });

    it('elevate customer selects ACH payment method then widget displayed', async () => {
        const element = createRd2EntryForm();
        const controller = new RD2FormController(element);
        await flushPromises();

        await setupWireMocksForElevate();
        controller.setDefaultInputFieldValues();

        controller.paymentMethod().changeValue('ACH');

        await flushPromises();

        const elevateWidget = controller.elevateWidget();
        expect(elevateWidget).toBeTruthy();
    });

    it('contact name is used for account holder name when tokenizing an ACH payment', async () => {
        mockGetIframeReply.mockImplementation((iframe, message, targetOrigin) => {
            // if message action is "createToken", reply with dummy token immediately
            // instead of trying to hook into postMessage
            // see sendIframeMessage in mocked psElevateTokenHandler
            if (message.action === 'createToken' || message.action === 'createAchToken') {
                return {"type": "post__npsp", "token": "a_dummy_token"};
            }
        });

        const element = createRd2EntryForm();
        const controller = new RD2FormController(element);

        await flushPromises();

        await setupWireMocksForElevate();

        controller.setDefaultInputFieldValues();

        controller.paymentMethod().changeValue('ACH');

        controller.contactLookup().changeValue('001fakeContactId');
        controller.amount().changeValue(1.00);

        await flushPromises();

        const elevateWidget = controller.elevateWidget();
        expect(elevateWidget).toBeTruthy();
        expect(elevateWidget.payerFirstName).toBe('John');

        const saveButton = selectSaveButton(element);
        saveButton.click();

        await flushPromises();

        expect(mockGetIframeReply).toHaveBeenCalledWith(
            expect.any(HTMLIFrameElement), // iframe
            expect.objectContaining({ // message
                action: "createAchToken",
                params: {
                    nameOnAccount: "John Smith",
                    accountHolder: {
                        type: "INDIVIDUAL",
                        firstName: "John",
                        lastName: "Smith"
                    }
                }
            }),
            expect.anything() // vf origin
        );
    });

});

const createRd2EntryForm = () => {
    const element = createElement('c-rd2-entry-form', {is: Rd2EntryForm});
    document.body.appendChild(element);
    return element;
}

const selectSaveButton = (element) => {
    return element.shadowRoot.querySelector('lightning-button[data-id="submitButton"]');
}

const setupWireMocksForElevate = async () => {
    getObjectInfo.emit(recurringDonationObjectInfo, config => {
        return config.objectApiName === RECURRING_DONATION_OBJECT.objectApiName;
    });

    getObjectInfo.emit(contactPartialDescribe, config => {
        return config.objectApiName.objectApiName === CONTACT_OBJECT.objectApiName;
    });

    getObjectInfo.emit(accountPartialDescribe, config => {
        return config.objectApiName.objectApiName === ACCOUNT_OBJECT.objectApiName;
    });

    getPicklistValues.emit(installmentPeriodPicklistValues, config => {
        return config.fieldApiName.fieldApiName === FIELD_INSTALLMENT_PERIOD.fieldApiName;
    });

    getPicklistValues.emit(dayOfMonthPicklistValues, config => {
        return config.fieldApiName.fieldApiName === FIELD_DAY_OF_MONTH.fieldApiName;
    });

    getRecord.emit(accountGetRecord, config => {
        return config.recordId === '001fakeAccountId';
    });

    getRecord.emit(contactGetRecord, config => {
        return config.recordId === '001fakeContactId';
    });

    await flushPromises();
}


class RD2FormController {
    element;

    constructor(element) {
        this.element = element;
    }

    setDefaultInputFieldValues() {
        this.recurringType().changeValue('Open');
        this.dateEstablished().changeValue('2021-02-03');
        this.startDate().changeValue('2021-02-03');
    }

    donorSection() {
        return this.element.shadowRoot.querySelector('c-rd2-entry-form-donor-section');
    }

    scheduleSection() {
        return this.element.shadowRoot.querySelector('c-rd2-entry-form-schedule-section');
    }

    elevateWidget() {
        return this.element.shadowRoot.querySelector('c-rd2-elevate-credit-card-form');
    }

    amount() {
        const field = this.element.shadowRoot.querySelector('lightning-input-field[data-id="amountField"]');
        return new RD2FormField(field);
    }

    dateEstablished() {
        const donorSection = this.donorSection();
        const field = donorSection.shadowRoot.querySelector('lightning-input-field[data-id="dateEstablished"]');
        return new RD2FormField(field);
    }

    contactLookup() {
        const donorSection = this.donorSection();
        const field = donorSection.shadowRoot.querySelector('lightning-input-field[data-id="contactLookup"]');
        return new RD2FormField(field);
    }

    paymentMethod() {
        const paymentMethod = this.element.shadowRoot.querySelector('lightning-input-field[data-id="paymentMethod"]');
        return new RD2FormField(paymentMethod);
    }

    recurringType() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-input-field[data-id="RecurringType__c"]');
        return new RD2FormField(field);
    }

    startDate() {
        const scheduleSection = this.scheduleSection();
        const field = scheduleSection.shadowRoot.querySelector('lightning-input-field[data-id="startDate"]');
        return new RD2FormField(field);
    }

    saveButton() {
        return element.shadowRoot.querySelector('lightning-button[data-id="submitButton"]');
    }
}

class RD2FormField {

    constructor(element) {
        this.element = element;
    }

    changeValue(value) {
        this.element.value = value;
        this.dispatchChangeEvent();
    }

    dispatchChangeEvent() {
        const { value } = this.element;
        this.element.dispatchEvent(new CustomEvent('change', { detail: { value } }));
    }
}