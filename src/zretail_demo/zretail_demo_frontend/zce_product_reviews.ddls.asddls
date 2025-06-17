@EndUserText.label: 'Gemini Retail Search Assistant for SAP'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PRODUCT_REVIEW_QIC'
@UI.headerInfo: {
    typeName: 'Gemini Retail Search Assistant for SAP',
    typeNamePlural: 'Gemini Retail Search Assistant for SAP',
    title: {
        type: #STANDARD,
        value: 'ProductID'
    },
    description: {
        type: #STANDARD,
        value: 'ProductID'
    }
}

define custom entity ZCE_PRODUCT_REVIEWS
{
      @UI.facet        : [
         {
            id         : 'idIdentification',
            type       : #IDENTIFICATION_REFERENCE,
            label      : 'Product search',
            position   : 10
          }]
      
      @EndUserText.label: 'Product ID'
      @ObjectModel.filter.enabled: false
      @UI.identification: [{ position: 10 }]
  key ProductId : abap.char(10);

  
      @EndUserText.label: 'Review Number'
      @UI.lineItem : [{ hidden: true }]
      @ObjectModel.filter.enabled: false
  key ReviewNo : abap.int1;

      @UI.lineItem: [{ type:#AS_DATAPOINT , 
                   position: 60, 
                   label: 'AI Generated Rating',
                   cssDefault.width: '15rem' }
                   ]
      @UI.dataPoint:{visualization:#RATING, 
                 title:'AI Generated Rating' }   
      @ObjectModel.filter.enabled: false 
      Rating      : abap.int1;
      
      @EndUserText.label: 'Review Text'
      @UI.lineItem : [{ position: 40, label: 'Review Text',cssDefault.width: '50rem' }]
      @ObjectModel.filter.enabled: false  
      ReviewText      : abap.string;   

      @UI.hidden    : true
      @ObjectModel.sort.enabled: false
      @ObjectModel.filter.enabled: false
      _Product    : association to parent ZCE_PRODUCT_READ on  $projection.ProductId   = _Product.ProductId;
}
