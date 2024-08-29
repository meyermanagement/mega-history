# Mega History App

A History Tracking app for fields not included in out of the box history tracking plus tracking create/delete/undelete events of child objects and the ability to see history tracking of records across multiple objects.  Integrated seemlessly with existing history tracking to save on storage space.

## Features

**Deployable configuration.**: 
* Generate necessary triggers dynamically in production directly or through a deployment process.
* Custom Metadata types control record history views and tracking configuration so they also can be deployed if desired.

**Enhanced history tracking on objects.**:
* Track as many fields as needed, beyond Salesforce limits

**View history of child records on parents**:
* CRUD History: See when child records were created, deleted, and undeleted on parent and/or grand-parent records
* See Field History of child records on parent records
* (future enhancements) control visibility based on FLS of current user
* (future enhancements) create different views based on profiles and/or record types

**Enhanced control/adjustment of history**:
* Create and Delete events to import history/rectify data
* Custom created date and created by field for historical data load to correctly merge data with standard history
* Cannot be used to modify existing standarad history but can supplement it


