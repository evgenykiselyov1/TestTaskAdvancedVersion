/**
 * @description       : This is a JS controller for scroll-bar of the available objects in the org
 * @author            : Ievgen Kyselov
 * @group             : 
 * @last modified on  : 06-01-2023
 * @last modified by  : Ievgen Kyselov
**/

import { LightningElement, track, wire, api } from 'lwc';
import getSobjects from '@salesforce/apex/JsonDataUploaderController.getEntityDefinitions';

export default class AvailableObjects extends LightningElement {
@track wiredSobjects = [];

isObjectSelected = false;
selectedObjectLabel;
selectedObjectName;

@wire(getSobjects)
getSobjects(result) {
    if (result.data) {
        let availableObjects = [];
        for (const [key, value] of Object.entries(result.data)) {
            let obj = { label: value, apiname: key };
            availableObjects.push(obj);
        }
        this.wiredSobjects = availableObjects;
    } else if (result.error) {
        this.error = result.error;
    }
}

showSelectedObject(event){
    this.isObjectSelected = true;
    for (const child of event.target.parentElement.children) {
        child.style.backgroundColor = '';
    }
    event.target.style.backgroundColor = 'lightsteelblue';
    this.selectedObjectLabel = event.target.outerText;
    this.selectedObjectName = event.target.getAttribute("data-target-id");
    
    const selectedEvent = new CustomEvent('selected', { detail: this.selectedObjectName });
    this.dispatchEvent(selectedEvent);
}

}