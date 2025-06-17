@EndUserText.label: 'Gemini Retail Search Assistant for SAP'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_PRODUCT_SEARCH_QIC'
@UI.headerInfo: {
    typeName: 'Gemini Retail Search Assistant for SAP',
    typeNamePlural: 'Gemini Retail Search Assistant for SAP',
    title: {
        type: #STANDARD,
        value: 'ProductID'
    },
    description: {
        type: #STANDARD,
        value: 'ProductName'
    }
}

define root custom entity ZCE_PRODUCT_READ
{
      @UI.facet        : [
         {
            id         : 'idIdentification',
            type       : #IDENTIFICATION_REFERENCE,
            label      : 'Product search',
            position   : 10
          },
          { id : 'idHeader' ,
                 type: #DATAPOINT_REFERENCE ,
                 label: 'Header' ,
                 purpose: #HEADER ,
                 targetQualifier: 'Rating'},          
          {
            id            : 'ProductReviews',
            purpose       : #STANDARD,
            type          : #LINEITEM_REFERENCE,
            label         : 'Product Reviews',
            position      : 20,
            targetElement : '_ProductReviews'
          }          ]
      
      @EndUserText.label: 'Product ID'
      @UI.lineItem     : [{ position: 20 }]
      @UI.identification: [{ position: 10 }]
      @ObjectModel.filter.enabled: false
  key ProductId : abap.char(10);

      @Semantics.imageUrl: true
      @UI.lineItem : [{ position: 30, label: ' ',cssDefault.width: '10rem' }]
      @ObjectModel.filter.enabled: false
      @UI.identification: [{ position: 20 }]
      ImageURL : abap.char(256);

      @EndUserText.label: 'Product Name'
      @UI.lineItem     : [{ position: 30 }]
      @ObjectModel.filter.enabled: false
      ProductName : abap.char(255);

      @EndUserText.label: 'Current Stock'
      @UI.lineItem     : [{ position: 40 }]
      @ObjectModel.filter.enabled: false
      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      @UI.identification: [{ position: 50 }]
      StockQuantity : abap.quan( 13, 3 );

      @EndUserText.label: 'Stock Unit'
      @UI.lineItem : [{ hidden: true }]
      @ObjectModel.filter.enabled: false
      QuantityUnit : abap.unit(3);

      @UI.lineItem: [{ type:#AS_DATAPOINT , 
                   position: 60, 
                   label: 'Average Rating',
                   cssDefault.width: '10rem'
                    }]
      @UI.dataPoint:{visualization:#RATING, 
                 title:'Average Rating' }   
      @ObjectModel.filter.enabled: false
      Rating      : abap.int1;
      
      @EndUserText.label: 'Search string'
      @UI.lineItem : [{ hidden: true }]
      @UI.selectionField: [{position: 10}]
      @ObjectModel.filter.enabled: true    
      @Search:{ defaultSearchElement: true, ranking: #MEDIUM }
      VectorSearchString      : abap.string;   
    
      @ObjectModel.filter.enabled: false
      _ProductReviews        : composition [0..*] of ZCE_PRODUCT_REVIEWS;
}
