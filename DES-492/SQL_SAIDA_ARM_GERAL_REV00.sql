-- BSP Data & BI Solutions --

-- Revision History --
-- Rev00: This is the first release of this code.

-- Notes --
-- Relatório De Saídas para Armazem Geral

select 

org.NAME                           Org
,tprem.TRX_NUMBER                   NF_Saida
,tprem.TRX_DATE
,tprem.SEFAZ_AUTHORIZATION_DATE
,tprem.RETURN_DATE
,tprem.SOURCE_CODE
,cta.SO
,cta.SO_Type
--,cta.CT_REFERENCE
,MSI.ITEM
,MSI.DESCRIPTION   
--,tprem.ITEM_DESCRIPTION
,tprem.SHIPPED_QUANTITY
,tprem.SUBINVENTORY
--,tprem.LOCATOR_ID
,LOC.LOCATOR
,tprem.LOT_NUMBER
,tprem.SERIAL_NUMBER
,tprem.UNIT_PRICE
,tprem.REMAINING_BALANCE
,tprem.SOURCE_SUBINVENTORY
--,tprem.SOURCE_LOCATOR_ID
,tprem.CANCEL_FLAG
,tprem.ERROR_FLAG
,DECODE(tprem.ERROR_FLAG,'Y','ERRO',
        'Transação concluída')  Status_SAÍDA
,tprem.TPA_REMIT_CONTROL_ID
,tprem.ORG_ID
,tprem.CUST_TRX_TYPE_ID
,tprem.CUSTOMER_TRX_ID
,tprem.CUSTOMER_TRX_LINE_ID
,tprem.DELIVERY_DETAIL_ID
,tprem.TRANSFER_ORGANIZATION_ID
,tprem.INVENTORY_ITEM_ID

from 
    apps.CLL_F513_TPA_REMIT_CONTROL tprem

left join (select INVENTORY_ITEM_ID,ORGANIZATION_ID,SEGMENT1 AS ITEM,DESCRIPTION from MTL_SYSTEM_ITEMS_B
            where ORGANIZATION_ID=4226) MSI
            ON tprem.ORGANIZATION_ID    =   MSI.ORGANIZATION_ID
            AND tprem.INVENTORY_ITEM_ID =   MSI.INVENTORY_ITEM_ID

left join (select MIL.ORGANIZATION_ID,MIL.INVENTORY_LOCATION_ID,DECODE (NVL(PPA.PROJECT,'x'),'x',MIL.SEGMENT1,(MIL.SEGMENT1||'|'||PPA.PROJECT)) AS LOCATOR  from MTL_ITEM_LOCATIONS MIL 
            left join (select PROJECT_ID,SEGMENT1 AS PROJECT from PA_PROJECTS_ALL) PPA
                        ON MIL.PROJECT_ID   =   PPA.PROJECT_ID
                        where MIL.ORGANIZATION_ID=4226)LOC
            ON tprem.ORGANIZATION_ID    =   LOC.ORGANIZATION_ID
            AND tprem.LOCATOR_ID        =   LOC.INVENTORY_LOCATION_ID
            
left join (select ORGANIZATION_ID, NAME from HR_ALL_ORGANIZATION_UNITS
            where ORGANIZATION_ID=4226)org
           ON  tprem.ORGANIZATION_ID    =   org.ORGANIZATION_ID

left join (select CUSTOMER_TRX_ID,INTERFACE_HEADER_ATTRIBUTE1 AS SO,INTERFACE_HEADER_ATTRIBUTE2 AS SO_Type,CT_REFERENCE,ORG_ID from RA_CUSTOMER_TRX_ALL)cta
            ON tprem.CUSTOMER_TRX_ID     =   cta.CUSTOMER_TRX_ID
            AND tprem.ORG_ID             =   cta.ORG_ID
        
where
1=1
and tprem.ORGANIZATION_ID=4226