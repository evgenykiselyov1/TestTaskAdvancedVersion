/**
 * @description       : This is a JS controller for UI of fileuploader
 * @author            : Ievgen Kyselov
 * @group             : 
 * @last modified on  : 06-01-2023
 * @last modified by  : Ievgen Kyselov
**/

import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from "lightning/alert";
import saveRecords from '@salesforce/apex/JsonDataUploaderController.saveRecords';
import setColumns from '@salesforce/apex/JsonDataUploaderController.setColumnsFromJSON';

export default class JsonDataUploader extends LightningElement {
    @track records = [];
    
    fileData = {};
    columns = [];
    selectedObject;

    pageSizeOptions = [5, 10, 25, 50, 75, 100]; //Page size options
    totalRecords = 0; //Total no.of records
    pageSize = 5; //No.of records to be displayed per page
    totalPages = 0; //Total no.of pages
    pageNumber = 0; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page
    
    get isDisableFirst() {
        return (this.pageNumber <= 1);
    }
    get isDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    get isDisabledSaveRecords(){
        return (this.selectedObject == undefined || this.fileData.filename == undefined);
    }

/**Set columns start*/

setNewColumns(name, data){
    setColumns({sobjectName: name, data: data})
    .then(result =>{
        let resultColumns = JSON.parse(result);
        let columns = [];
        let column0 = {label : 'Sequence Number', fieldName : 'rowNumber', type : 'number'};
        columns.push(column0);
        resultColumns.forEach(element => {
            let column = {};
            column.fieldName = element.name;
            column.label = element.label;
            column.type = element.type;
            if(column.type == 'date'){
                column.typeAttributes = { year: 'numeric', month: 'numeric', day: 'numeric'};
            }
            columns.push(column);
        });
        this.columns = columns;

        this.saveNewRecords(name, data);
    })
    .catch(error => {
        LightningAlert.open({
            message: 'Something wrong with the fields: ' + error.body.message,
            theme: "error",
            label: "Error with saving the records"
        }).then(() => {
        
        });
        return;
    });

}

saveNewRecords(sobjectName, data){
    saveRecords({sobjectName: sobjectName, data: data})
    .then(result=>{
        for (let i = 0; i < result.length; i++) {
            result[i].rowNumber = i+1;
        }
        this.records = result;
        this.totalRecords = result.length; // update total records count  
        this.paginationHelper(); // call helper menthod to update pagination logic 
        this.fileData = {};
        this.showToast('Records are created successfully!', '', 'success');
    })
    .catch(error => {
        LightningAlert.open({
            message: 'Something went wrong: ' + error.body.message,
            theme: "error",
            label: "Error with saving the records"
        }).then(() => {
        });
        return;
    });
}

setObjectName(event){
    this.selectedObject = event.detail;
}

    /**File uploader code block start*/
    openfileUpload(event) {
        const file = event.target.files[0];
        var fileSize = Math.round((file.size / 1048576));
        /*Validation of file size. Couldn't be more than 3.5 mb because of lightning-input component SF limitation*/
        if(fileSize > 3.5){
            LightningAlert.open({
                message: "Selected file exceeds the limit of 3.5 MB. Please choose another file or reduce the selected one.",
                theme: "error",
                label: "File " +  file.name + " is too large"
            }).then(() => {
            });
        }else{
            var reader = new FileReader();
            reader.onload = () => {
                var base64 = reader.result.split(',')[1];
                this.fileData = {
                    'filename': file.name,
                    'base64': base64
                }
            }
            reader.readAsDataURL(file);
        }
    }
    
    handleClick(){
        const {base64, filename} = this.fileData;
        this.showToast('The file is uploaded', 'The process is running', 'warning');
        this.setNewColumns(this.selectedObject, base64);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
/**File uploader code block finish*/

/**Pagination code block start*/

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }
    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }
    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1 && this.totalPages > 0) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        if(this.totalPages > 0){
            for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
                if (i === this.totalRecords) {
                    break;
                }
                this.recordsToDisplay.push(this.records[i]);
            }            
        }

    }

/**Pagination code block finish*/

}